import os
from PIL import Image

def generate_icons():
    master_path = "assets/icon/icon.jpg"
    if not os.path.exists(master_path):
        print(f"Error: {master_path} does not exist.")
        return

    img = Image.open(master_path).convert("RGBA")
    
    # Save master PNG
    img.save("assets/icon/icon.png", format="PNG")
    print("Saved assets/icon/icon.png")

    # 1. Android
    android_targets = {
        "android/app/src/main/res/mipmap-mdpi/ic_launcher.png": (48, 48),
        "android/app/src/main/res/mipmap-hdpi/ic_launcher.png": (72, 72),
        "android/app/src/main/res/mipmap-xhdpi/ic_launcher.png": (96, 96),
        "android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png": (144, 144),
        "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png": (192, 192),
    }
    for path, size in android_targets.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(path, format="PNG")
        print(f"Generated Android icon: {path} ({size[0]}x{size[1]})")

    # 2. iOS
    ios_base = "ios/Runner/Assets.xcassets/AppIcon.appiconset"
    ios_targets = {
        "Icon-App-20x20@1x.png": (20, 20),
        "Icon-App-20x20@2x.png": (40, 40),
        "Icon-App-20x20@3x.png": (60, 60),
        "Icon-App-29x29@1x.png": (29, 29),
        "Icon-App-29x29@2x.png": (58, 58),
        "Icon-App-29x29@3x.png": (87, 87),
        "Icon-App-40x40@1x.png": (40, 40),
        "Icon-App-40x40@2x.png": (80, 80),
        "Icon-App-40x40@3x.png": (120, 120),
        "Icon-App-60x60@2x.png": (120, 120),
        "Icon-App-60x60@3x.png": (180, 180),
        "Icon-App-76x76@1x.png": (76, 76),
        "Icon-App-76x76@2x.png": (152, 152),
        "Icon-App-83.5x83.5@2x.png": (167, 167),
        "Icon-App-1024x1024@1x.png": (1024, 1024),
    }
    for fname, size in ios_targets.items():
        path = os.path.join(ios_base, fname)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(path, format="PNG")
        print(f"Generated iOS icon: {path} ({size[0]}x{size[1]})")

    # 3. macOS
    macos_base = "macos/Runner/Assets.xcassets/AppIcon.appiconset"
    macos_targets = {
        "app_icon_16.png": (16, 16),
        "app_icon_32.png": (32, 32),
        "app_icon_64.png": (64, 64),
        "app_icon_128.png": (128, 128),
        "app_icon_256.png": (256, 256),
        "app_icon_512.png": (512, 512),
        "app_icon_1024.png": (1024, 1024),
    }
    for fname, size in macos_targets.items():
        path = os.path.join(macos_base, fname)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(path, format="PNG")
        print(f"Generated macOS icon: {path} ({size[0]}x{size[1]})")

    # 4. Web
    web_targets = {
        "web/favicon.png": (32, 32),
        "web/icons/Icon-192.png": (192, 192),
        "web/icons/Icon-512.png": (512, 512),
        "web/icons/Icon-maskable-192.png": (192, 192),
        "web/icons/Icon-maskable-512.png": (512, 512),
    }
    for path, size in web_targets.items():
        os.makedirs(os.path.dirname(path), exist_ok=True)
        resized = img.resize(size, Image.Resampling.LANCZOS)
        resized.save(path, format="PNG")
        print(f"Generated Web icon: {path} ({size[0]}x{size[1]})")

    # 5. Windows ICO
    ico_path = "windows/runner/resources/app_icon.ico"
    os.makedirs(os.path.dirname(ico_path), exist_ok=True)
    # Windows icon multi-size
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    img.save(ico_path, format="ICO", sizes=ico_sizes)
    print(f"Generated Windows ICO: {ico_path} with sizes {ico_sizes}")

    print("\nAll platform icons successfully generated!")

if __name__ == "__main__":
    generate_icons()

