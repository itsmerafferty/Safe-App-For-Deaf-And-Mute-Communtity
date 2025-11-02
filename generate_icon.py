from PIL import Image, ImageDraw, ImageFont
import os

def create_safe_icon(size):
    """Create SAFE app icon with emergency alert design"""
    
    # Create image with gradient-like purple background
    img = Image.new('RGB', (size, size), color='#764ba2')
    draw = ImageDraw.Draw(img)
    
    # Draw gradient effect (simulated with rectangles)
    for i in range(size):
        ratio = i / size
        r = int(102 + (118 - 102) * ratio)
        g = int(126 + (75 - 126) * ratio)
        b = int(234 + (162 - 234) * ratio)
        color = (r, g, b)
        draw.rectangle([(0, i), (size, i+1)], fill=color)
    
    # Draw semi-transparent circle background
    center_x, center_y = size // 2, size // 2
    circle_radius = int(size * 0.35)
    
    # Draw alert triangle (emergency symbol)
    triangle_size = int(size * 0.4)
    triangle_points = [
        (center_x, center_y - triangle_size // 2),  # Top
        (center_x - triangle_size // 2, center_y + triangle_size // 2),  # Bottom left
        (center_x + triangle_size // 2, center_y + triangle_size // 2),  # Bottom right
    ]
    draw.polygon(triangle_points, fill='white')
    
    # Draw exclamation mark inside triangle
    line_height = int(size * 0.15)
    line_width = int(size * 0.04)
    line_x = center_x - line_width // 2
    line_y = center_y - line_height // 2
    draw.rectangle(
        [(line_x, line_y), (line_x + line_width, line_y + line_height)],
        fill='#667eea'
    )
    
    # Draw exclamation dot
    dot_size = int(size * 0.03)
    dot_y = center_y + line_height // 2 + int(dot_size * 1.5)
    draw.ellipse(
        [(center_x - dot_size, dot_y - dot_size),
         (center_x + dot_size, dot_y + dot_size)],
        fill='#667eea'
    )
    
    # Add "SAFE" text at bottom
    try:
        # Try to use a bold font
        font_size = int(size * 0.12)
        try:
            font = ImageFont.truetype("arial.ttf", font_size)
        except:
            try:
                font = ImageFont.truetype("arialbd.ttf", font_size)
            except:
                font = ImageFont.load_default()
        
        text = "SAFE"
        # Get text bounding box
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_x = (size - text_width) // 2
        text_y = int(size * 0.85) - font_size // 2
        
        draw.text((text_x, text_y), text, fill='white', font=font)
    except Exception as e:
        print(f"Could not add text: {e}")
    
    return img

def main():
    """Generate app icons in various sizes"""
    
    # Create assets/icon directory if it doesn't exist
    icon_dir = "assets/icon"
    os.makedirs(icon_dir, exist_ok=True)
    
    print("🎨 Generating SAFE App Icons...")
    
    # Generate main icon (1024x1024 for iOS)
    sizes = {
        'safe_app_icon.png': 1024,
        'icon-192.png': 192,
        'icon-512.png': 512,
    }
    
    for filename, size in sizes.items():
        print(f"  Creating {filename} ({size}x{size})...")
        icon = create_safe_icon(size)
        icon.save(os.path.join(icon_dir, filename), 'PNG')
        print(f"  ✅ {filename} created!")
    
    print("\n✅ All icons generated successfully!")
    print(f"📁 Icons saved in: {os.path.abspath(icon_dir)}")
    print("\n📋 Next steps:")
    print("  1. Run: flutter pub get")
    print("  2. Run: flutter pub run flutter_launcher_icons")
    print("  3. Build your app!")

if __name__ == "__main__":
    main()
