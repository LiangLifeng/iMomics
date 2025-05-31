import numpy as np
import pandas as pd

# 设置参数
n_samples = 100        # 样本数
n_features = 1000      # 基因数量（特征维度）
n_informative = 50     # 与标签有关的特征数量
random_state = 42
rng = np.random.default_rng(seed=random_state)

# 创建特征矩阵
X = rng.standard_normal((n_samples, n_features))

# 引入部分信息信号：前 n_informative 个特征与标签有关
y = np.array([0] * (n_samples // 2) + [1] * (n_samples // 2))  # 50 健康, 50 疾病
for i in range(n_informative):
    X[y == 1, i] += 2.0  # 疾病组在这些特征上提升均值

# 转换为 DataFrame
X_df = pd.DataFrame(X, columns=[f"Gene_{i+1}" for i in range(n_features)])
y_df = pd.DataFrame({'Sample': [f"S{i+1}" for i in range(n_samples)], 'Disease': y})

# 添加 Sample ID 作为 index
X_df.insert(0, "Sample", y_df["Sample"])
X_df.set_index("Sample", inplace=True)
y_df.set_index("Sample", inplace=True)

# 保存为 TSV 文件
X_df.to_csv("demo_expression.tsv", sep="\t")
y_df.to_csv("demo_labels.tsv", sep="\t")

print("✅ Demo 数据已生成: demo_expression.tsv + demo_labels.tsv")
