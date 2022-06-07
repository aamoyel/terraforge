# Terraform VM Forge
<div id="top"></div>

[![asciicast](https://asciinema.org/a/499315.svg)](https://asciinema.org/a/499315)

<!-- TABLE OF CONTENTS -->
<details open>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>
</br>



<!-- ABOUT THE PROJECT -->
## About The Project

This project allows you to create fresh VMs instances on Proxmox.
Tools like Cloud-Init, HashiCorp Vault, phpIPAM and PowerDNS are integrated to automate and simplify VMs configurations. Features are:
- Dynamic password generation for root user with Vault.
- Get the first IP addr of subnet of your choise with phpIPAM
- Configurate VM network, hostname and root password at start.
- Create dns record with your VM name and IP addr.

<p align="right">(<a href="#top">back to top</a>)</p>



### Built With

* [Proxmox](https://www.proxmox.com)
* [Cloud-Init](https://cloud-init.io/)
* [HashiCorp Vault](https://www.vaultproject.io/)
* [phpIPAM](https://phpipam.net/)
* [PowerDNS](https://www.powerdns.com/)

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

You need to have an instance of :
* Proxmox
* HashiCorp Vault
* phpIPAM
* PowerDNS

After that, you need to have a cloud-init template in Proxmox and [terraform binary](https://learn.hashicorp.com/tutorials/terraform/install-cli) on a PC/server.

### Installation

1. Clone the repo :
   ```sh
   git clone https://github.com/aamoyel/terraforge
   ```
2. Configure your APIs credentials and URLs in terraform.tfvars.json.
3. Init your terraform directory and install deps.
   ```sh
   terraform init
   ```

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- USAGE EXAMPLES -->
## Usage

1. Setup your VMs in vm-instances.json, exemple here :
   ```json
    {
      "my-vm-name": {
        "cores": "2",
        "sockets": "1",
        "memory": "2048",
        "network": "vmbr1",
        "subnet": "PRD",
        "domain": "amoyel.loc"
      }
    }
   ```
2. Create the instance :
   ```sh
   terraform apply
   ```

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- LICENSE -->
## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#top">back to top</a>)</p>



<!-- CONTACT -->
## Contact

Alan Amoyel - [@AlanAmoyel](https://twitter.com/AlanAmoyel)

Project Link: [https://github.com/aamoyel/terraforge](https://github.com/aamoyel/terraforge)

<p align="right">(<a href="#top">back to top</a>)</p>
