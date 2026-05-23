import os
from PIL import Image

def crop_and_square_icon(input_path, output_path, padding_percent=0.03):
    img = Image.open(input_path).convert("RGBA")
    
    # Get the bounding box of alpha > 0
    bbox = img.getbbox()
    if not bbox:
        print("Image is entirely transparent")
        return
        
    left, top, right, bottom = bbox
    cropped = img.crop((left, top, right, bottom))
    
    # Dimensions of the cropped image
    w, h = cropped.size
    
    # Determine the size of the square canvas
    max_dim = max(w, h)
    
    # Size with padding
    padded_dim = int(max_dim / (1.0 - 2.0 * padding_percent))
    
    # Create new transparent square image
    new_img = Image.new("RGBA", (padded_dim, padded_dim), (0, 0, 0, 0))
    
    # Calculate offset to center the cropped image
    offset_x = (padded_dim - w) // 2
    offset_y = (padded_dim - h) // 2
    
    new_img.paste(cropped, (offset_x, offset_y))
    
    # Resize to standard size, say 512x512
    final_img = new_img.resize((512, 512), Image.Resampling.LANCZOS)
    
    # Save the result
    final_img.save(output_path)
    print(f"Icon cropped and saved to {output_path}.")
    print(f"Original: {img.size}, Cropped: {cropped.size}, Final: 512x512 (padding: {padding_percent*100}%)")

if __name__ == "__main__":
    src = "assets/icon/fletch.png"
    backup = "assets/icon/fletch_backup.png"
    if not os.path.exists(backup):
        os.rename(src, backup)
        crop_and_square_icon(backup, src, padding_percent=0.03)
    else:
        crop_and_square_icon(backup, src, padding_percent=0.03)
