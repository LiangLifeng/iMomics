import argparse
import numpy as np
import pandas as pd
from sklearn.preprocessing import StandardScaler
from sklearn.decomposition import PCA
from sklearn.linear_model import LogisticRegression
from sklearn.pipeline import make_pipeline
from sklearn.model_selection import cross_val_score, GridSearchCV
from sklearn.metrics import classification_report, confusion_matrix, roc_auc_score
import matplotlib.pyplot as plt
import joblib


def main():
    parser = argparse.ArgumentParser(description="Principal Component Regression with Classification")
    parser.add_argument("--expression", type=str, required=True, help="Path to expression matrix (TSV). Rows=samples, columns=features.")
    parser.add_argument("--labels", type=str, required=True, help="Path to label file (TSV). Must contain sample IDs and class labels.")
    parser.add_argument("--label-column", type=str, required=True, help="Column name in label file to use as target variable.")
    parser.add_argument("--sep", type=str, default="\t", help="Delimiter for input files. Default is tab.")
    parser.add_argument("--output-prefix", type=str, default="pcr_result", help="Prefix for output files.")
    args = parser.parse_args()

    # 读取数据
    X_df = pd.read_csv(args.expression, sep=args.sep, index_col=0)
    y_df = pd.read_csv(args.labels, sep=args.sep, index_col=0)
    
    # 校验 sample 对齐
    X_df = X_df.loc[y_df.index]
    y = y_df[args.label_column].values

    # 标准化
    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X_df)

    # PCA 拟合
    pca = PCA()
    X_pca = pca.fit_transform(X_scaled)
    explained_variance_ratio = pca.explained_variance_ratio_
    cumulative_variance = np.cumsum(explained_variance_ratio)

    # 保存碎石图
    plt.figure(figsize=(8, 5))
    plt.plot(range(1, len(cumulative_variance) + 1), cumulative_variance, marker='o', linestyle='--')
    plt.axhline(y=0.9, color='r', linestyle='-', label='90% Variance')
    plt.xlabel('Number of Principal Components')
    plt.ylabel('Cumulative Explained Variance Ratio')
    plt.title('Scree Plot')
    plt.legend()
    plt.savefig(f"{args.output_prefix}_scree_plot.png", dpi=300, bbox_inches='tight')
    plt.close()

    # GridSearchCV 寻找最佳主成分数量
    max_components = min(50, X_scaled.shape[1])
    param_grid = {
        'pca__n_components': range(1, max_components + 1),
        'logisticregression__C': [0.01, 0.1, 1, 10, 100]
    }
    pcr_pipeline = make_pipeline(StandardScaler(), PCA(), LogisticRegression(max_iter=1000))
    grid_search = GridSearchCV(pcr_pipeline, param_grid, cv=5, scoring='accuracy')
    grid_search.fit(X_df, y)

    best_n = grid_search.best_params_['pca__n_components']
    best_C = grid_search.best_params_['logisticregression__C']
    print(f"Best n_components: {best_n}, C: {best_C}")

    # 用最佳参数重新训练模型
    final_pipeline = make_pipeline(StandardScaler(), PCA(n_components=best_n), LogisticRegression(C=best_C, max_iter=1000))
    final_pipeline.fit(X_df, y)
    joblib.dump(final_pipeline, f"{args.output_prefix}_pcr_model.pkl")

    # 预测评估
    y_pred = final_pipeline.predict(X_df)
    y_proba = final_pipeline.predict_proba(X_df)[:, 1]

    # 输出评估
    print("\nConfusion Matrix:\n", confusion_matrix(y, y_pred))
    print("\nClassification Report:\n", classification_report(y, y_pred))
    print("\nROC AUC:", roc_auc_score(y, y_proba))

    # 保存预测概率分布图
    plt.figure(figsize=(8, 5))
    plt.hist(y_proba[y == 0], bins=20, alpha=0.5, label='Class 0', color='blue')
    plt.hist(y_proba[y == 1], bins=20, alpha=0.5, label='Class 1', color='red')
    plt.xlabel('Predicted Probability')
    plt.ylabel('Count')
    plt.title('Probability Distribution')
    plt.legend()
    plt.savefig(f"{args.output_prefix}_probability_distribution.png", dpi=300, bbox_inches='tight')
    plt.close()

    # 保留前 best_n 个主成分的载荷矩阵
    pca_model = PCA(n_components=best_n)
    pca_model.fit(X_scaled)

    loadings_df = pd.DataFrame(
        pca_model.components_.T,
        index=X_df.columns,
        columns=[f"PC{i+1}" for i in range(best_n)]
    )

    # 保存完整的载荷矩阵
    loadings_df.to_csv(f"{args.output_prefix}_loadings.tsv", sep='\t')

    # 分析每个 PC 中 top 贡献基因，并保存
    top_contributors = {}
    for i in range(best_n):
        pc = f"PC{i+1}"
        top_genes = loadings_df[pc].abs().sort_values(ascending=False).head(10)
        top_contributors[pc] = top_genes

    # 合并成一个 DataFrame 保存
    top_contributors_df = pd.concat(top_contributors, axis=1)
    top_contributors_df.to_csv(f"{args.output_prefix}_top_genes.tsv", sep='\t')

    #加权主成分贡献（基因总体影响力排序）
    explained_ratio = pca_model.explained_variance_ratio_  # 长度 = best_n
    weighted_loadings = loadings_df.abs().multiply(explained_ratio, axis=1)
    gene_influence = weighted_loadings.sum(axis=1).sort_values(ascending=False)

    # 保存 top 20 重要基因（综合所有 PC 的影响力）
    gene_influence.head(20).to_csv(f"{args.output_prefix}_top_genes_weighted.tsv", sep='\t', header=['WeightedContribution'])


if __name__ == "__main__":
    main()
