source <(nerdctl completion bash | awk '{gsub(/nerdctl/, "docker"); print $0}')

#export CONTAINERD_SNAPSHOTTER=fuse-overlayfs
alias pg-start="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^postgres-.+/ && (\$3==\"Created\" || \$3==\"Exited\")) print \$1}' | xargs nerdctl start"
alias pg-stop="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^postgres-.+/ && \$3==\"Up\") print \$1}' | xargs nerdctl stop"
alias pg-cli="docker run -e TZ=Asia/Shanghai -it --network postgres --rm amd64/postgres:14.5-alpine psql 'postgresql://vmi:vmi.%409_z!6@postgres-0:5432/vmi'"


alias mongo-start="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^mongo-.+/ && (\$3==\"Created\" || \$3==\"Exited\")) print \$1}' | xargs nerdctl start"
alias mongo-stop="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^mongo-.+/ && \$3==\"Up\") print \$1}' | xargs nerdctl stop"
alias mongo-cli="docker run -e TZ=Asia/Shanghai -it --network mongo --rm amd64/mongo:6.0.1 mongosh --quiet 'mongodb://mongo-0:27017'"

alias redis-start="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^redis-.+/ && (\$3==\"Created\" || \$3==\"Exited\")) print \$1}' | xargs nerdctl start"
alias redis-stop="nerdctl ps -a --format '{{.ID}} {{.Names}} {{.Status}}' | awk '{if(\$2 ~ /^redis-.+/ && \$3==\"Up\") print \$1}' | xargs nerdctl stop"
alias redis-cli="docker run -e TZ=Asia/Shanghai -it --network redis --rm redis:7.0.4-alpine redis-cli -h redis-0 -p 6379 -c -a '123456'"
alias docker="nerdctl"