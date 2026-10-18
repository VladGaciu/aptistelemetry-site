from PIL import Image, ImageDraw, ImageFont

# --- Configuration ---
ICON_SIZE = 512  # High resolution for crisp scaling
BG_COLOR = (9, 13, 22, 0)  # Matches Scaffold Background (0xFF090D16) with transparency
ACCENT_CYAN = (56, 189, 248) # Matches Primary Color (0xFF38bdf8)
WHITE = (255, 255, 255)
TRANSPARENT = (0, 0, 0, 0)

def create_circular_mask(size):
    """Creates a soft circular mask for the icon."""
    if isinstance(size, tuple):
        w, h = size
    else:
        w = h = size
        
    mask = Image.new('L', (w, h), 0)
    draw = ImageDraw.Draw(mask)
    padding = w // 10
    draw.ellipse((padding, padding, w - padding, h - padding), fill=255)
    return mask

def generate_icon_1_target(filename):
    """Concept 1: The Precision Target (Cyan Reticle)."""
    img = Image.new('RGBA', (ICON_SIZE, ICON_SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    
    cx, cy = ICON_SIZE // 2, ICON_SIZE // 2
    r_outer = ICON_SIZE * 0.45
    r_inner = ICON_SIZE * 0.05
    
    # Draw subtle outer glow circle
    glow_radius = r_outer + (ICON_SIZE * 0.02)
    draw.ellipse((cx-glow_radius, cy-glow_radius, cx+glow_radius, cy+glow_radius), fill=(*ACCENT_CYAN, 50))

    # Draw main reticle circle (Cyan)
    draw.ellipse((cx-r_outer, cy-r_outer, cx+r_outer, cy+r_outer), outline=ACCENT_CYAN, width=6)
    
    # Draw crosshairs
    line_thickness = 8
    # Horizontal
    draw.rectangle((0, cy - line_thickness//2, ICON_SIZE, cy + line_thickness//2), fill=ACCENT_CYAN)
    # Vertical
    draw.rectangle((cx - line_thickness//2, 0, cx + line_thickness//2, ICON_SIZE), fill=ACCENT_CYAN)
    
    # Draw center dot (White)
    dot_r = r_outer * 0.15
    draw.ellipse((cx-dot_r, cy-dot_r, cx+dot_r, cy+dot_r), fill=WHITE)

    # Apply circular mask
    mask = create_circular_mask((ICON_SIZE, ICON_SIZE))
    final_img = Image.composite(img, Image.new('RGBA', (ICON_SIZE, ICON_SIZE), BG_COLOR), mask)
    final_img.save(filename)
    print(f"Generated: {filename}")

def generate_icon_2_gaussian(filename):
    """Concept 2: Gaussian Beam Profile."""
    img = Image.new('RGBA', (ICON_SIZE, ICON_SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)

    cx, cy = ICON_SIZE // 2, ICON_SIZE // 2
    
    # Draw 3D effect "hill" (Concentric semi-transparent circles)
    max_r = ICON_SIZE * 0.45
    num_rings = 15
    for i in range(num_rings):
        r = max_r * (1 - (i/num_rings)**2) # Parabolic scaling for 3D look
        opacity = int(255 * (1 - (i/num_rings)**0.5))
        draw.ellipse((cx-r, cy-r, cx+r, cy+r), outline=(*ACCENT_CYAN, opacity), width=4)
        
    # Draw Crosshairs on top
    draw.line((cx, cy - max_r*1.1, cx, cy + max_r*1.1), fill=(*ACCENT_CYAN, 200), width=5)
    draw.line((cx - max_r*1.1, cy, cx + max_r*1.1, cy), fill=(*ACCENT_CYAN, 200), width=5)
    # Center point
    draw.ellipse((cx-10, cy-10, cx+10, cy+10), fill=WHITE)

    # Apply circular mask
    mask = create_circular_mask((ICON_SIZE, ICON_SIZE))
    final_img = Image.composite(img, Image.new('RGBA', (ICON_SIZE, ICON_SIZE), BG_COLOR), mask)
    final_img.save(filename)
    print(f"Generated: {filename}")

def generate_icon_3_airy(filename):
    """Concept 3: Airy Disk Diffraction Pattern."""
    img = Image.new('RGBA', (ICON_SIZE, ICON_SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    
    cx, cy = ICON_SIZE // 2, ICON_SIZE // 2
    
    # Bright central spot
    core_r = ICON_SIZE * 0.12
    draw.ellipse((cx-core_r, cy-core_r, cx+core_r, cy+core_r), fill=WHITE)
    
    # The First Dark Ring (Background Color)
    ring1_r = ICON_SIZE * 0.22
    draw.ellipse((cx-ring1_r, cy-ring1_r, cx+ring1_r, cy+ring1_r), outline=BG_COLOR, width=35)
    
    # The First Bright Ring (Cyan)
    ring2_r = ICON_SIZE * 0.38
    draw.ellipse((cx-ring2_r, cy-ring2_r, cx+ring2_r, cy+ring2_r), outline=ACCENT_CYAN, width=25)

    # Crosshairs
    draw.line((cx, cy - ring2_r*1.2, cx, cy + ring2_r*1.2), fill=(200,200,200,150), width=3)
    draw.line((cx - ring2_r*1.2, cy, cx + ring2_r*1.2, cy), fill=(200,200,200,150), width=3)

    # Apply circular mask
    mask = create_circular_mask((ICON_SIZE, ICON_SIZE))
    final_img = Image.composite(img, Image.new('RGBA', (ICON_SIZE, ICON_SIZE), BG_COLOR), mask)
    final_img.save(filename)
    print(f"Generated: {filename}")

def generate_icon_4_monogram(filename):
    """Concept 4: Stylized 'E' (Engineering) with laser vectors."""
    img = Image.new('RGBA', (ICON_SIZE, ICON_SIZE), TRANSPARENT)
    draw = ImageDraw.Draw(img)
    
    cx, cy = ICON_SIZE // 2, ICON_SIZE // 2
    
    # Define points for a stylized 'E' rotated 45 deg, or an intersecting vector plot
    # We'll draw a stylized 'E' using thick lines, intersecting with a targeting reticle
    
    # Coordinates for a blocky E (rotated slightly to look dynamic)
    # (This is hard to draw perfectly with primitive shapes without a vector path, 
    #  so we'll use a large bold 'E' from a font instead, as it's cleaner).

    try:
        # Try to load a font. If not available, fall back to basic drawing.
        # On Linux, this usually works, but path varies.
        font = ImageFont.truetype("DejaVuSans-Bold.ttf", ICON_SIZE)
    except IOError:
        print("Font not found, generating fallback icon instead.")
        generate_icon_1_target(filename) # Fallback to concept 1
        return

    text = "E"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    text_x = cx - text_width // 2
    text_y = cy - text_height // 2
    
    # Draw the 'E' in Cyan, but with transparency
    draw.text((text_x, text_y), text, font=font, fill=(*ACCENT_CYAN, 200))
    
    # Draw crosshairs over the 'E'
    draw.line((cx, cy - ICON_SIZE*0.4, cx, cy + ICON_SIZE*0.4), fill=WHITE, width=6)
    draw.line((cx - ICON_SIZE*0.4, cy, cx + ICON_SIZE*0.4, cy), fill=WHITE, width=6)

    # Apply circular mask
    mask = create_circular_mask((ICON_SIZE, ICON_SIZE))
    final_img = Image.composite(img, Image.new('RGBA', (ICON_SIZE, ICON_SIZE), BG_COLOR), mask)
    final_img.save(filename)
    print(f"Generated: {filename}")

if __name__ == "__main__":
    print("Generating icons...")
    generate_icon_1_target("app_icon_1_target.png")
    generate_icon_2_gaussian("app_icon_2_gaussian.png")
    generate_icon_3_airy("app_icon_3_airy.png")
    generate_icon_4_monogram("app_icon_4_monogram.png")
    print("Done. Check the folder for PNG files.")