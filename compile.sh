#!/bin/bash

# MLC-LLM 编译脚本
# 用途：自动化编译 MLC-LLM 项目，包括环境设置、模型转换和编译
# 默认配置：使用 CUDA 12.1, 编译为 Android 目标设备

set -e  # 遇到错误立即退出

# ==================== 可配置变量 ====================
# 项目根目录（默认为当前用户目录下的 mlc-llm）
PROJECT_ROOT=$(pwd)
# 目标设备（可选：cuda, android, vulkan等）
TARGET_DEVICE="cuda"
# CUDA 路径（如果目标设备为 cuda）
CUDA_PATH="/usr/local/cuda-13.0"
# ===================================================

# 日志函数
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
    exit 1
}

# 检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "命令 $1 未找到，请安装后再运行脚本。"
    fi
}

# 检查目录是否存在
check_directory() {
    if [ ! -d "$1" ]; then
        log_error "目录 $1 不存在，请检查路径。"
    fi
}

# 安装系统依赖
install_dependencies() {
    log_info "安装系统依赖..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update
        sudo apt-get install -y git build-essential cmake ninja-build doxygen libssl-dev
    else
        log_error "不支持的包管理器，请手动安装依赖。"
    fi

    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2404/x86_64/cuda-keyring_1.1-1_all.deb
    sudo dpkg -i cuda-keyring_1.1-1_all.deb
    sudo apt-get update
    sudo apt-get install -y cuda-toolkit-13-0
    rm -f cuda-keyring_1.1-1_all.deb

    # echo "export PATH=/usr/local/cuda-13-0/bin:$PATH" >> ~/.bashrc
    # echo "export LD_LIBRARY_PATH=/usr/local/cuda-13-0/lib64:$LD_LIBRARY_PATH" >> ~/.bashrc
    source ~/.bashrc

    # 检查 CUDA 安装
    nvcc --version || log_error "CUDA 安装失败，请检查。"
    nvidia-smi || log_error "NVIDIA 驱动未正确安装，请检查。"
}

compile_mlc_llm() {
    log_info "开始编译 MLC-LLM..."

    cd "${PROJECT_ROOT}"
    if [ ! -d "build" ]; then mkdir -p build; fi

    cd build
    cmake ..
    make -j4
}

# 主函数
main() {
    log_info "开始 MLC-LLM 编译流程..."

    # 检查必要命令
    check_command git
    check_command cmake
    check_command python3

    # # 步骤执行
    # install_dependencies
    compile_mlc_llm

    log_info "编译完成！"
}

# 执行main函数
main "$@"
