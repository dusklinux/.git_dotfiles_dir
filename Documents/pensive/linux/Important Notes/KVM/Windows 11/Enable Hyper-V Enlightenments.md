Hyper-V Enlightenments allow KVM to emulate the Microsoft Hyper-V hypervisor. This improves the performance of the Windows 11 virtual machine.

For more information, check out the pages [[Hyper-V Enlightenments]] and [[Hypervisor Features]]

Click the XML tab and replace the hyprv section with this. 

> [!danger] This is ONLY for 12700H cpu, If you have another cpu, leave your's as is, the default is usually automatically optimized for the cpu in use
 
```bash
  <hyperv>
	<relaxed state="on"/>
	<vapic state="on"/>
	<spinlocks state="on" retries="8191"/>
	<vpindex state="on"/>
	<runtime state="on"/>
	<synic state="on"/>
	<stimer state="on">
		<direct state="on"/>
	</stimer>
	<reset state="on"/>
	<vendor_id state="on" value="KVM Hv"/>
	<frequencies state="on"/>
	<reenlightenment state="on"/>
	<tlbflush state="on"/>
	<ipi state="on"/>
	<evmcs state="on"/>
	<avic state="on"/>
  </hyperv>
```


`Apply`