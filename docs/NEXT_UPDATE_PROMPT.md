# Prompt cho model tiếp theo — U1.12ad world-boss capture lifecycle

Tiếp tục bằng đúng một package U1.12ad: audit và đóng lifecycle khi world boss bị capture/despawn ngoài defeat. Creature phải signal stable removal reason sau accepted ownership commit nhưng trước free; Main chỉ chuyển owned `boss.world_dragon_1` sang terminal state một lần. Không đổi capture reward/roster và không để actor thường/altar ảnh hưởng world state. Regression phủ capture success, reject/no-op, duplicate callback và save sau capture không respawn boss. Chạy full gate + leak-aware log scan và cập nhật docs.
