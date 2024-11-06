#!/bin/bash

# 设置动态库存放路径
dylib_dir="./lib"

# 查找所有的 .dylib 文件（包括二进制和 .dylib 库文件）
binaries_and_dylibs=$(find . -name "*.dylib" -o -type f -perm +111)

# 遍历每个文件，可能是二进制文件或 .dylib 文件
for file in $binaries_and_dylibs; do
    echo "处理文件: $file"

    # 获取该文件的所有依赖库路径
    dependencies=$(otool -L "$file" | awk '{print $1}' | grep -v ':')

    # 遍历每个依赖库路径
    for dependency in $dependencies; do
        # 如果是绝对路径，且不指向系统库（/usr/lib 或 /System/Library）
        if [[ "$dependency" == /* && ! "$dependency" =~ ^/usr/lib && ! "$dependency" =~ ^/System/Library ]]; then
            # 获取依赖库的文件名
            dependency_filename=$(basename "$dependency")
            
            # 构建新的依赖路径
            new_dependency="@executable_path/lib/$dependency_filename"
            
            # 检查依赖库文件是否存在于当前目录的 lib/ 目录
            if [ -f "$dylib_dir/$dependency_filename" ]; then
                echo "修改依赖路径: $dependency -> $new_dependency"
                install_name_tool -change "$dependency" "$new_dependency" "$file"
                if [ $? -eq 0 ]; then
                    echo "修改成功"
                else
                    echo "修改失败"
                fi
            else
                echo "依赖库不存在，跳过修改: $dependency"
            fi
        fi
    done
    echo "==============================="
done
