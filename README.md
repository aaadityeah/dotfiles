# dotfiles

## Hammerspoon

Remaps Caps Lock to:
- **Tap** → Escape
- **Hold** → Control

### Setup on a new Mac

1. Install Hammerspoon:
   ```bash
   brew install --cask hammerspoon
   ```

2. Clone this repo and symlink the Hammerspoon config:
   ```bash
   git clone https://github.com/aaadityeah/dotfiles.git ~/personal/src/dotfiles
   ln -s ~/personal/src/dotfiles/hammerspoon ~/.hammerspoon
   ```

3. Open Hammerspoon:
   ```bash
   open -a Hammerspoon
   ```

4. Grant **Accessibility** permission when prompted:
   System Settings → Privacy & Security → Accessibility → enable Hammerspoon

5. Add Hammerspoon to login items so it starts on boot:
   System Settings → General → Login Items & Extensions → add Hammerspoon
