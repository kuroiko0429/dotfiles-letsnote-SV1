#!/bin/bash

# エラーがあったら即止まるようにする
set -e

echo "Starting Setup for SV1 Beast Mode..."

# 1. まずシステムを更新 & 必須ツールインストール
echo "Installing Base Packages..."
sudo pacman -Syu --noconfirm
sudo pacman -S --needed --noconfirm git base-devel

# 2. Yay のインストールチェック & インストール
if ! command -v yay &> /dev/null; then
    echo "Yay not found. Installing Yay..."
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay
    makepkg -si --noconfirm
    cd -
    rm -rf /tmp/yay
else
    echo "Yay is already installed."
fi

# 3. 公式パッケージのインストール
# コメント行(#)を無視して、リストをpacmanに渡す
echo "Installing Official Packages from list..."
if [ -f ./packages/packages_repo.txt ]; then
    sed 's/#.*//' ./packages/packages_repo.txt | xargs sudo pacman -S --needed --noconfirm
else
    echo "packages_repo.txt not found!"
fi

# 4. AURパッケージのインストール
# コメント行(#)を無視して、リストをyayに渡す
echo "Installing AUR Packages from list..."
if [ -f ./packages/packages_aur.txt ]; then
    sed 's/#.*//' ./packages/packages_aur.txt | xargs yay -S --needed --noconfirm
else
    echo "packages_aur.txt not found!"
fi

echo "All Done! Enjoy your Arch Linux on SV1!"

# 5. Oh My Zsh & Powerlevel10k Setup
echo "Setting up Zsh & Powerlevel10k..."

# Oh My Zsh のインストール (既にあったらスキップ)
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # --unattended をつけることで、スクリプトを止めずにインストールする
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# プラグインとテーマのインストール先定義
ZSH_CUSTOM=${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}

# Powerlevel10k のクローン
if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
    echo "Cloning Powerlevel10k..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
fi

# Plugins のクローン
echo "Cloning Zsh Plugins..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
fi

# .zshrc の書き換え
echo "Configuring .zshrc..."

# テーマを powerlevel10k に変更
sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc

# プラグイン設定 (改行を含まず1行で書いたほうがsedがコケにくいのでおすすめ)
sed -i 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# デフォルトシェルを zsh に変更
# (パスワードを聞かれるかもしれないけど、それはsudoの仕様)
echo "Changing default shell to zsh..."
sudo chsh -s $(which zsh) $USER

echo "Zsh setup complete! Please restart your terminal."

# 6. fcitx5 ~/.bash_profile & /etc/environment 

sed -i 's/#export GTK_IM_MODULE="fcitx5"/export GTK_IM_MODULE=fcitx5/' ~/.bash_profile
sed -i 's/#export QT_IM_MODULE="fcitx5"/export QT_IM_MODULE=fcitx5/' ~/.bash_profile
sed -i 's/#export XMODIFIERS='@im=fcitx5'/export XMODIFIERS=@im=fcitx5/' ~/.bash_profile

sed -i 's/#export GTK_IM_MODULE="fcitx5"/export GTK_IM_MODULE=fcitx5/' /etc/environment
sed -i 's/#export QT_IM_MODULE="fcitx5"/export QT_IM_MODULE=fcitx5/' /etc/environment
sed -i 's/#export XMODIFIERS='@im=fcitx5'/export XMODIFIERS=@im=fcitx5/' /etc/environment
