import sys
import cv2
from ultralytics import YOLO

def apply_blur(image, box, mode='mosaic'):
    x1, y1, x2, y2 = map(int, box)
    
    # 画像の範囲内に収める
    h, w, _ = image.shape
    x1, y1 = max(0, x1), max(0, y1)
    x2, y2 = min(w, x2), min(h, y2)
    
    if x1 >= x2 or y1 >= y2:
        return image

    roi = image[y1:y2, x1:x2]
    
    if mode == 'blur':
        # ガウスぼかしモード
        kw = max(1, (x2 - x1) // 10) | 1
        kh = max(1, (y2 - y1) // 10) | 1
        blurred_roi = cv2.GaussianBlur(roi, (kw * 2 + 1, kh * 2 + 1), 30)
        image[y1:y2, x1:x2] = blurred_roi
    else:
        # モザイクモード（デフォルト）
        factor = 15 # 数値が大きいほど粗いモザイクになる
        rw = max(1, (x2 - x1) // factor)
        rh = max(1, (y2 - y1) // factor)
        
        small = cv2.resize(roi, (rw, rh), interpolation=cv2.INTER_LINEAR)
        mosaic = cv2.resize(small, (x2 - x1, y2 - y2 + (y2 - y1)), interpolation=cv2.INTER_NEAREST)
        image[y1:y2, x1:x2] = mosaic

    return image

def process_video(input_path, output_path, mode='mosaic'):
    # YOLOv8モデルの読み込み
    model = YOLO("python_engine/yolov8n.pt")

    cap = cv2.VideoCapture(input_path)
    if not cap.isOpened():
        print(f"Error: Could not open input video: {input_path}")
        return

    fps = cap.get(cv2.CAP_PROP_FPS)
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fourcc = cv2.VideoWriter_fourcc(*'mp4v')
    out = cv2.VideoWriter(output_path, fourcc, fps, (width, height))

    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break

        results = model(frame, verbose=False)
        
        for r in results:
            boxes = r.boxes
            for box in boxes:
                cls = int(box.cls[0])
                # 人物（class 0）を検知した場合に処理
                if cls == 0:
                    xyxy = box.xyxy[0].tolist()
                    frame = apply_blur(frame, xyxy, mode=mode)

        out.write(frame)

    cap.release()
    out.release()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        print("Usage: python processor.py <input_path> <output_path> [mode]")
        sys.exit(1)

    inp = sys.argv[1]
    outp = sys.argv[2]
    proc_mode = sys.argv[3] if len(sys.argv) > 3 else 'mosaic'

    process_video(inp, outp, mode=proc_mode)