# EasyInstall

Welcome to EasyInstall, an automatic installation script collection designed to simplify the installation process for various software packages. With EasyInstall, you can easily install common software and tools using a single command.

## Project Overview

EasyInstall provides a convenient way to install various packages. Users can quickly install the required software by running a simple curl command, without the need to manually download and configure.

## Usage

To install a specific package, use the following command:

```sh
sh <(curl -s https://ezi.sh/[package_name])
```
Replace `[package_name]` with the name of the desired package. For example, to install homebrew, you would use:

```sh
sh <(curl -s https://ezi.sh/homebrew)
```

## Available Packages

All available installation packages can be found at [packages.json](https://github.com/woolflare/EasyInstall/blob/main/packages.json).

### Examples

Below are examples of installing some common packages:

**Homebrew:**

```sh
sh <(curl -s https://ezi.sh/homebrew)
```

**Node Version Manager (NVM):**

```sh
sh <(curl -s https://ezi.sh/nvm)
```

**Oh My Zsh:**

```sh
sh <(curl -s https://ezi.sh/ohmyzsh)
```

## Contribution

We welcome contributions to the EasyInstall project, including new installation scripts or improvements to existing ones. If you would like to contribute, please follow these steps:

1. Fork this repository.
2. Create your feature branch (`git checkout -b feature/your-feature`).
3. Commit your changes (`git commit -am 'Add some feature'`).
4. Push to the branch (`git push origin feature/your-feature`).
5. Create a new Pull Request.

## Support

If you encounter any issues while using EasyInstall or have suggestions, please submit an issue through GitHub Issues.

## License

This project is licensed under the MIT License.
