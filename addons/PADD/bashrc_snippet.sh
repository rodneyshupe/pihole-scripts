echo "Launch PADD..."
if [ "$TERM" == "linux" ] || [ "$TERM" == "xterm-color" ]; then
    while :
    do
        bash padd.sh
        sleep 1
    done
fi
