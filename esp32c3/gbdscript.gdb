set remotetimeout 10
target remote :3333
monitor reset halt
maintenance flush register-cache
thbreak creator-esp.c:70
b main
continue