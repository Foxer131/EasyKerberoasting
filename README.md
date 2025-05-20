# EasyKerberoasting
A simple powershell script that utilizes PowerView to perform a Kerberoast attack, the target of the attack can be selected.

## Usage
After importing PowerView the tool can be used. Simply do

```
./Kerberoasting.ps1
```
The tool will scan available SPNs, the tool will then display a list of available targets.
Type in a number and the tool will output the requested TGS, this can be cracked offline via hashcat/john
