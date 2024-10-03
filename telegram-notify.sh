#!/bin/bash

# Lưu vào tệp: telegram-bot.sh
# Ví dụ: ./telegram-bot.sh "370022700" "83633434:kewkekekekdkkfiirrjririrjr" 1 "Notify: NOTIFICATIONTYPE 0XzXZ0 Host: HOSTNAME 0XzXZ0 Service: SERVICEDESC 0XzXZ0 Date: SHORTDATETIME 0XzXZ0 Info: SERVICEOUTPUT"

CHAT_ID="$1"
BOT_TOKEN="$2"
FLAG="$3"
MESSAGE="$4"
LOG_DIR="$(dirname "$0")/log"
LOG_FILE="$LOG_DIR/$(date +%d%m%Y)_telegram.log"

# Kiểm tra và tạo thư mục log nếu chưa tồn tại
mkdir -p "$LOG_DIR"

# Kiểm tra đầu vào
if [[ -z "$FLAG" || "$FLAG" != "1" ]]; then
    echo "Flag must be = 1. Exit."
    exit 1
fi

if [[ -z "$CHAT_ID" ]]; then
    echo "Not input chat_id. Exit."
    exit 1
fi

if [[ -z "$BOT_TOKEN" ]]; then
    echo "Not input botToken. Exit."
    exit 1
fi

# Ghi log
log() {
    echo "$(date '+%d.%m.%Y %H:%M:%S') : $1" >> "$LOG_FILE"
}

# Ghi log khởi động
log "-------------------------------------------------------------------"

# Hàm thay thế ký tự dòng
replace_linebreak() {
    local msg="$1"
    echo "$msg" | sed 's/0XzXZ0/\n/g'
}

# Hàm gửi tin nhắn đến Telegram
send_msg_to_telegram() {
    local bot_token="$1"
    local telegram_chat_id="$2"
    local message="$(replace_linebreak "$3")"
    local url="https://api.telegram.org/bot$bot_token/sendMessage"

    # Gửi yêu cầu đến Telegram
    response=$(curl -s -X POST "$url" -d "chat_id=$telegram_chat_id&text=$(urlencode "$message")")
    echo "$response" | grep -q '"ok":true'
}

urlencode() {
    local str="$1"
    echo -n "$str" | jq -sRr @uri
}

# Xử lý gửi tin nhắn
IFS=',' read -r -a telegram_groups <<< "$CHAT_ID"

for telegram_chat_id in "${telegram_groups[@]}"; do
    log "------------ START posting to $telegram_chat_id ------------"

    if send_msg_to_telegram "$BOT_TOKEN" "$telegram_chat_id" "$MESSAGE"; then
        log "Message was SENT to telegram $telegram_chat_id"
    else
        log "Message was NOT sent to telegram $telegram_chat_id"
    fi

    log "------------ END posting to $telegram_chat_id ------------"
done

# Xóa log cũ mỗi 30 ngày
find "$LOG_DIR" -name "*.log" -ctime +30 -exec rm {} \;

