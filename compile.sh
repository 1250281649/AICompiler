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

# 提取物理核心数（每个插槽的核心数 × 插槽数）
PHYSICAL_CORES=$(lscpu -p | awk -F, '/^[^#]/ {core=$2} END {print core+1}')
echo "物理CPU核心数: $PHYSICAL_CORES"

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

compile_tvm() {
    log_info "开始编译 TVM..."

    tvm_home=${PROJECT_ROOT}/3rdparty/tvm
    cd ${tvm_home}
    tvm_build=${tvm_home}/build
    if [ ! -d "${tvm_build}" ]; then
        log_info "目录 ${tvm_build} 不存在，自动创建该目录。"
        mkdir -p ${tvm_build}
    fi

    cp ${PROJECT_ROOT}/cmake/tvm_config.cmake ${tvm_home}/build/config.cmake
    cd ${tvm_build}

    cmake ..
    make -j$PHYSICAL_CORES
}

compile_mlc_llm() {
    log_info "开始编译 MLC-LLM..."

    mlc_home=${PROJECT_ROOT}/3rdparty/mlc-llm
    cd ${mlc_home}
    mlc_build=${mlc_home}/build
    if [ ! -d "${mlc_build}" ]; then
        log_info "目录 ${mlc_build} 不存在，自动创建该目录。"
        mkdir -p ${mlc_build}
    fi

    cp ${PROJECT_ROOT}/cmake/mlc_llm_config.cmake ${mlc_build}/config.cmake
    cd ${mlc_build}
    cmake ..
    make -j$PHYSICAL_CORES
}

# 主函数
main() {
    # 检查必要命令
    check_command git
    check_command cmake
    check_command python3

    compile_tvm

    log_info "开始 MLC-LLM 编译流程..."

    # # 步骤执行
    compile_mlc_llm

    log_info "编译完成！"
}

# 执行main函数
main "$@"
