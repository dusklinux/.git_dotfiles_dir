
 ### Verifying ZRAM Status with `zramctl`

After configuring ZRAM, you can monitor its performance and verify its status using the `zramctl` command-line utility.

> [!NOTE]
> The `zramctl` command provides a real-time overview of all active ZRAM devices, including their size, compression algorithm, and current memory usage.

### Check ZRAM Statistics

To view the statistics for all active ZRAM devices, run the following command:

```bash
zramctl
```

### Example Output

The output will resemble the following, providing a detailed summary of each device:

```
NAME       ALGORITHM DISKSIZE  DATA  COMPR  TOTAL STREAMS MOUNTPOINT
/dev/zram0 zstd           32G  1.9G 318.6M 424.9M      16 [SWAP]
```

### Understanding the Output

The output columns provide key metrics about your ZRAM setup:

| Column | Description | Example Value |
|---|---|---|
| `NAME` | The name of the ZRAM device. | `/dev/zram0` |
| `ALGORITHM` | The compression algorithm in use. | `zstd` |
| `DISKSIZE` | The maximum uncompressed size of the ZRAM device. | `32G` |
| `DATA` | The current amount of uncompressed data stored. | `1.9G` |
| `COMPR` | The compressed size of the data currently stored. | `318.6M` |
| `TOTAL` | The total physical RAM used, including compressed data and metadata. | `424.9M` |
| `STREAMS` | The number of parallel compression streams available. | `16` |
| `MOUNTPOINT`| Where the device is mounted (e.g., as swap space). | `[SWAP]` |

> [!TIP] Analyzing Compression Efficiency
> In the example above, **1.9 GiB** of data (`DATA`) has been compressed down to just **318.6 MiB** (`COMPR`). This demonstrates the significant memory savings provided by ZRAM. The total physical RAM footprint, including overhead, is only **424.9 MiB** (`TOTAL`).

