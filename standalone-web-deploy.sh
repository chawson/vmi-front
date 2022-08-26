#!/bin/bash

set -e

# 支持部署的合法服务列表
supportSvrs=(
    test-deploy
)

# 打包输出的目录 [选项 -d]
distDir="./dist/"

# 指定压缩文件 [选项 -f]
tarFile=""

# 远程服务器，例如 root@localhost [选项 -r]
serverHost=""

# 服务器WorkDir, 请以`/`开头和结尾，例如/web/ [选项 -p]
serverRoot=""

# 参数
deploySvr=""

# 是否使用mock测试效果
isLocalDeploy=1

# 指定tar文件 
specialFile=""

# 输出提示
helpMessage() {
    echo "用法: ./deploy.sh -r <serverHost> <-p <serverRoot>|-t> [-f <tarFile>] [-d <distDir>] <websvr>"
    echo "示例:"
    echo -e "\t./deploy.sh -r root@localhost -p \$(pwd) test-deploy"
    echo "参数："
    echo -e "\twebsvr: web名称，必须和openresty配置的\`root\`的\`basename\`一致，\n\t\t且不能为\"/\"(斜线),\"..\"(若干个点)等。已经支持的websvr:"
    for svr in ${supportSvrs[*]};
    do
        echo -e "\t\t$svr"
    done
    echo "选项:"
    echo -e "\t-d <distDir>: 指定Web项目打包输出的目录,默认./dist/"
    echo -e "\t-f <tarFile>: 指定压缩文件,本机跳过压缩操作"
    echo -e "\t-r <serverHost>: 指定远程服务器的ssh登录账号,例如root@localhost"
    echo -e "\t-p <serverRoot>: 指定远程服务器的工作目录绝对路径,例如/workspace/"
    echo -e "\t-t: 在本地测试部署, 存在此选项时-r参数将不被使用"
    echo "帮助:"
    echo -e "\t ./deploy.sh -h"
}

checkDeploySvr() {
    success=1

    for svr in ${supportSvrs[*]};
    do
        if [ "$deploySvr" = "$svr" ];
        then
            success=0
            break
        fi
    done

    if [ $success -ne 0 ]
    then
        echo "web服务【$deploySvr】暂不支持"
        helpMessage
        exit 2
    fi

    # 当不使用支持列表时，补充校验
    bn=$(basename ./$deploySvr/)
    if [[ "$bn" != "$deploySvr" || "$bn" =~ ^\.+$ || "$bn" == "/" ]];
    then
        echo "非法目录【$deploySvr】,不允许部署"
        helpMessage
        exit 2
    fi
}

# 规范化初始参数
initArgs() {
    if [[ "$serverRoot" =~ /$ ]];
    then
        serverRoot="$serverRoot/"
    fi
}

# 检验打包输出目录
checkDistDir() {
    if [ ! -d $distDir ];
    then
        echo "打包输出目录${distDir}不存在,请检查或-d指定目录"
        exit 2
    fi

    filesCount=$(ls $distDir | wc -w)
    if [ $filesCount -eq 0 ]
    then
        echo "打包输出目录${distDir}是空目录,请检查或-d指定目录"
        exit 2
    fi
}

checkServerRoot() {
    if [[ ! "$serverRoot" =~ ^/ ]];
    then
        echo "远程服务器工作目录[-p]必须为绝对路径"
        exit 2
    fi
}

checkFuncArgLen() {
    # 本函数的正常参数 "{方法名}" ${参数数量} {当前方法的所有参数}
    # 检查是否为2个参数，避免没传的参数被替代
    methodName=$1
    shift
    argsLen=$1
    shift

    if [ $# -lt $argsLen ];
    then
        #echo "【${methodName}参数个数至少${argsLen}个】"
        #echo "【缺少参数可能由空字符串导致】"
        echo "Error: 【$1】"
        helpMessage
        exit 2
    fi
}

checkEmptyArgs() {
    checkFuncArgLen "checkEmptyArgs" 2 "$@"
    # 不允许为空字符串
    if [ -z "$1" ];
    then
        echo $2
        helpMessage
        exit 2
    fi
}

checkArg() {
    checkFuncArgLen "checkArg" 2 "$@"
    # 不允许开头为 -
    if [[ "$1" =~ ^- ]];
    then
        echo $2
        helpMessage
        exit 2
    fi
}

# 处理输入参数/选项
parseArgs() {
    while [ -n "$1" ];
    do
        case "$1" in
            -p)
                checkArg $2 "非法的远程服务器工作目录: err $1"
                serverRoot="$2"
                shift
            ;;
            -r)
                checkArg $2 "非法的远程服务器: err $1"
                serverHost="$2"
                shift
            ;;
            -d)
                checkArg $2 "非法的打包目录: err $1"
                distDir="$2"
                shift
            ;;
            -f)
                checkArg $2 "指定的文件不允许以-开头: err $1"
                specialFile="$2"
                shift
            ;;
            -h)
                helpMessage
                exit
            ;;
            -t)
                isLocalDeploy=0
            ;;
            --)
                shift
                break
            ;;
            *)
                if [ -z "$deploySvr" ];
                then
                    deploySvr="$1"
                fi
            ;;
        esac
        shift
    done
}

# 执行部署
execDeploy() {
    checkDeploySvr

    # tar 解压压缩的格式 J|j|z|等
    tarFileFormat=""

    if [ -z "$specialFile" ];
    then
        checkDistDir
        echo "压缩dist目录"
        tar -cJf $deploySvr.txz -C $distDir . --remove-files
        specialFile="$deploySvr.txz"
        tarFileFormat="J"
    else
        if [ ! -f $specialFile ];
        then
            echo "Err: -f 【${specialFile}不是文件类型】"
            exit 2
        fi
        fileType=$(file $specialFile | awk '{print $2}' | tr '[[:upper:]]' '[[:lower:]]')
        case "$fileType" in
            xz)
                tarFileFormat="J"
            ;;
            gzip|gunzip|unzip)
                tarFileFormat="z"
            ;;
            bzip2)
                tarFileFormat="j"
            ;;
            posix|pax|gnu|ustar)
            ;;
            *)
                echo "Err: -f 【tar解压不支持${specialFile}文件格式】"
                exit 2
            ;;
        esac
    fi

    
        
    execBin="bash"

    if [ $isLocalDeploy -ne 0 ];
    then
        execBin="ssh -q -o StrictHostKeyChecking=no $serverHost"
        # 判断服务器是否存在目录，不存在则创建
        $execBin <<-EOF
        set -e
        if [ ! -d $serverRoot ];
        then
            mkdir -p $serverRoot
            if [ $? -ne 0 ];
            then
                exit 2
            fi
        fi
        exit
EOF
        echo "上传到服务器"
        scp -o StrictHostKeyChecking=no -r $specialFile $serverHost:$serverRoot
    fi

    echo "开始部署,请等待..."
    $execBin <<-EOF
    set -e
    cd $serverRoot
    deploySupportSvr="${supportSvrs[*]}"
    
    success=1

    for svr in \$deploySupportSvr;
    do
        if [ \$svr == "$deploySvr" ];
        then
            success=0
            break
        fi
    done
    
    if [ \$success -eq 0 ];
    then
        if [ -d ./$deploySvr ];
        then
            filesCount=\$(ls ./$deploySvr | wc -w)
            if [ \$filesCount -gt 0 ];
            then
                tar -cJf $deploySvr.bak.txz -C ./$deploySvr/ . --remove-files
                if [ \$? -ne 0 ];
                then
                    echo "备份失败"
                    exit 2
                fi
            fi
        fi

        if [ ! -d ./$deploySvr ];
        then
            mkdir -p ./$deploySvr
        fi

        mkdir -p ./$deploySvr
        tar -"x${tarFileFormat}f" $specialFile -C ./$deploySvr
        chmod -R 755 ./$deploySvr
        echo "部署完成"
    else
        echo "部署失败，没有配置支持的服务"
    fi
    exit
EOF
}

# 解析命令行传参参数
parseArgs $*
# 基本检查
checkServerRoot
# 首次检查不可为空的参数
checkEmptyArgs $distDir "请传入build输出目录选项 -d"
checkEmptyArgs $serverRoot "请传入服务器工作目录选项 -p"
checkEmptyArgs $deploySvr "请传入需要部署的web名称参数"

if [ $isLocalDeploy -ne 0 ];
then
    checkEmptyArgs $serverHost "请传入ssh登录账号选项 -r"
fi

# 规范化命令行参数
initArgs

# 执行部署
execDeploy
