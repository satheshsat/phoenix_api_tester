import os
import shutil
import subprocess
from PIL import Image

def generate_icons():
    # Use PNG if available, fallback to JPG
    master_path = "assets/icon/icon.png"
    if not os.path.exists(master_path):
        master_path = "assets/icon/icon.jpg"
    
    if not os.path.exists(master_path):
        print(f"Error: Neither assets/icon/icon.png nor assets/icon/icon.jpg exists.")
        return

    img = Image.open(master_path).convert("RGBA")
    
    # Save master PNG
    os.makedirs("assets/icon", exist_ok=True)
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
    ico_sizes = [(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)]
    img.save(ico_path, format="ICO", sizes=ico_sizes)
    print(f"Generated Windows ICO: {ico_path} with sizes {ico_sizes}")

    # 6. Linux Runner Resources & Hicolor Icons
    linux_res_dir = "linux/runner/resources"
    os.makedirs(linux_res_dir, exist_ok=True)
    
    # 512x512 app_icon.png
    linux_app_icon = os.path.join(linux_res_dir, "app_icon.png")
    img.resize((512, 512), Image.Resampling.LANCZOS).save(linux_app_icon, format="PNG")
    print(f"Generated Linux runner icon: {linux_app_icon} (512x512)")

    # Standard Linux hicolor sizes
    hicolor_sizes = [16, 24, 32, 48, 64, 128, 256, 512]
    user_home = os.path.expanduser("~")
    user_icons_base = os.path.join(user_home, ".local", "share", "icons", "hicolor")

    # Generate Linux workspace icons
    for s in hicolor_sizes:
        repo_icon_path = os.path.join(linux_res_dir, "icons", f"{s}x{s}", "apps", "phoenix.api.tester.png")
        os.makedirs(os.path.dirname(repo_icon_path), exist_ok=True)
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(repo_icon_path, format="PNG")
        print(f"Generated Linux hicolor icon: {repo_icon_path}")

    # Optional: Install directly into user's ~/.local/share/icons/ and applications/ if writable
    try:
        for s in hicolor_sizes:
            user_icon_path = os.path.join(user_icons_base, f"{s}x{s}", "apps", "phoenix.api.tester.png")
            os.makedirs(os.path.dirname(user_icon_path), exist_ok=True)
            resized = img.resize((s, s), Image.Resampling.LANCZOS)
            resized.save(user_icon_path, format="PNG")
            print(f"Installed to user icon theme: {user_icon_path}")

        user_pixmaps = os.path.join(user_home, ".local", "share", "pixmaps")
        os.makedirs(user_pixmaps, exist_ok=True)
        img.resize((512, 512), Image.Resampling.LANCZOS).save(
            os.path.join(user_pixmaps, "phoenix.api.tester.png"), format="PNG"
        )
        print(f"Installed to user pixmaps: {user_pixmaps}/phoenix.api.tester.png")

        desktop_src = "linux/phoenix.api.tester.desktop"
        if os.path.exists(desktop_src):
            user_apps_dir = os.path.join(user_home, ".local", "share", "applications")
            os.makedirs(user_apps_dir, exist_ok=True)
            dest_desktop = os.path.join(user_apps_dir, "phoenix.api.tester.desktop")
            
            with open(desktop_src, "r", encoding="utf-8") as f:
                content = f.read()

            cwd = os.getcwd()
            release_bin = os.path.join(cwd, "build/linux/x64/release/bundle/phoenix_api_tester")
            debug_bin = os.path.join(cwd, "build/linux/x64/debug/bundle/phoenix_api_tester")
            exec_path = release_bin if os.path.exists(release_bin) else (debug_bin if os.path.exists(debug_bin) else "phoenix_api_tester")
            
            user_content = content.replace("Exec=phoenix_api_tester", f"Exec={exec_path}")
            with open(dest_desktop, "w", encoding="utf-8") as f:
                f.write(user_content)
            print(f"Installed desktop launcher to: {dest_desktop} (Exec={exec_path})")

        try:
            subprocess.run(["update-desktop-database", os.path.join(user_home, ".local", "share", "applications")], check=False)
        except Exception:
            pass
        try:
            subprocess.run(["gtk-update-icon-cache", "-f", user_icons_base], check=False)
        except Exception:
            pass
    except (OSError, PermissionError) as e:
        print(f"Note: Could not install to user directory ({e}). Project icons were generated successfully.")

    print("\nAll platform icons successfully generated and Linux desktop icons installed!")

if __name__ == "__main__":
    generate_icons()
