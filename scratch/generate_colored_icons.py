import colorsys
from PIL import Image

def adjust_hue(image_path, output_path, target_hue):
    """
    Adjusts the hue of non-grayscale pixels to target_hue (0.0 to 1.0).
    Green: ~0.33 (120 degrees)
    Orange: ~0.08 (30 degrees)
    """
    img = Image.open(image_path).convert("RGBA")
    pixels = img.load()
    width, height = img.size
    
    for y in range(height):
        for x in range(width):
            r_val, g_val, b_val, a_val = pixels[x, y]
            if a_val > 0:
                h, s, v = colorsys.rgb_to_hsv(r_val/255.0, g_val/255.0, b_val/255.0)
                if s > 0.05:
                    h = target_hue
                nr, ng, nb = colorsys.hsv_to_rgb(h, s, v)
                pixels[x, y] = (int(nr*255), int(ng*255), int(nb*255), a_val)
                
    img.save(output_path)
    print(f"Generated {output_path} with target hue {target_hue}")

if __name__ == "__main__":
    src = "assets/icon/fletch.png"
    # Green for Dev
    adjust_hue(src, "assets/icon/fletch_dev.png", 0.33)
    # Orange for Staging
    adjust_hue(src, "assets/icon/fletch_staging.png", 0.08)
