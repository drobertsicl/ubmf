# Un Break My Files

A highly unoptimised R script to regenerate missing .IDX files from Waters raw .DAT files

### There is something wrong with me and I would like to understand the structure of .IDX files

Waters raw data, at least for imaging, is stored as a continuous, ordered series of 8 byte hex values, where the first 4 bytes encode the intensity somehow, the last 4 bytes encode the m/z value.

Helpfully, even though I haven't figured out fully how the m/z value is encoded, the final byte encodes the integer part of the m/z value, which is then subject to further operations encoded in the other bytes. These start at hex value `36`  and end at value `5C`, meaning we can simply look for the sudden change between 1200 m/z at the end of  one scan to 50 m/z at the start of another to determine how many data points are supposed to be in this scan.

Each scan has a corresponding 30 byte series of metadata values:

![](https://github.com/drobertsicl/ubmf/blob/main/memorymap.png)

The number of data points and corresponding memory positions are calculated by observing jumps in the last m/z integer byte in the .DAT file

### There is nothing wrong with me and I would like to just use it, thanks

The ubmf.R script is fairly self explanatory, however there are some caveats:

- Check your desired .DAT with a hex editor such as the web-based [hexed.it](http://hexed.it "hexed.it") and ensure it's not simply 10 gigabytes of 00
- You probably need a lot of RAM, and it is extremely unoptimised
- While this allows for full access to spectra data points in SeeMS that are identical to the baseline .IDX file, there are minor differences in the size of peak picked mzML files. The actual data output is identical despite this, though other applications may have other issues
