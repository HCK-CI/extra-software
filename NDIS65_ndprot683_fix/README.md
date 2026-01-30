The latest HLK for Windows 11 24H2/25H2 and Windows Server 2025 contains a bugged NDISTest 6.5 ndprot683.sys driver.
As a result, 14 tests failed due to network packet corruption detection.

As a workaround, the provided configuration files automate the replacement of ndprot683.sys with a file from HLK for Windows Server 2022.
Since NDISTest 6.5 from HLK for Windows Server 2022 also contains unsigned protocols (another bug), use ndprot683.sys from NDISTest 6.0 from HLK for Windows Server 2022 instead.

Can't commit ndprot683.sys due to MSFT redistributable license.
