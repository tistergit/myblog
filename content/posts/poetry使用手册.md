---
title: "poetry使用手册"
date: 2024-03-22
draft: false
---

poetry 是一个 Python 打包和依赖管理工具，旨在简化 Python 包的创建、发布和依赖管理。与传统的 setuptools、pip 和 requirements.txt 的组合相比，poetry 提供了一个统一和简化的工具和工作流程。

以下是关于 poetry 的详细介绍：

## 主要特点

- 声明式的依赖管理: 通过 pyproject.toml 文件，你可以明确地指定项目的依赖和版本。
- 自动生成 lock 文件: 类似于 JavaScript 的 yarn 或 Ruby 的 Bundler，poetry 会生成一个 poetry.lock 文件，确保在所有环境中的依赖都是确定和一致的。
- 虚拟环境管理: 默认情况下，poetry 为每个项目自动创建和管理一个虚拟环境。
- 包构建和发布: 使用单个工具，你可以构建和发布你的包到 PyPI。
- 完整的依赖解析: poetry 有一个强大的依赖解析算法，确保项目的所有依赖都是相容的，且没有版本冲突。
- 管理 Python 版本: 你可以在 pyproject.toml 文件中指定 Python 的版本，确保所有开发者和环境使用同样版本的 Python。

## 使用方法

- 安装
  
    ```shell
    curl -sSL https://install.python-poetry.org | python3 -
    ```

- 创建新项目:
    ```shell
    poetry new project-name
    ```

- 添加新的依赖:
    ```shell
    poetry add package-name
    ```

- 安装依赖:
    ```shell
    poetry install
    ```

- 查看虚拟环境路径:
    ```shell
    poetry env info --path
    ```

- 定义和使用脚本:

    在 pyproject.toml 文件中，您可以定义脚本，类似于 npm 的脚本。例如：
    ```
    [tool.poetry.scripts]
    start = "python main.py"
    ```

    然后，您可以使用以下命令来运行该脚本：
    ```shell
    poetry run start
    ```
    这将执行 python main.py，而且这个命令将在 Poetry 的虚拟环境中执行。