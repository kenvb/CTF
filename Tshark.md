# Tshark Command Summary

This document provides a comprehensive summary of various **tshark** commands for analyzing packet captures. It covers reading files, applying filters, following TCP streams, extracting files, finding email addresses, and output formatting with the **`-T`** option.

## 1. Reading a Capture File

**Command:**

    tshark -r capture.pcap

**Explanation:**  
Reads and displays all packets from the capture file `capture.pcap`.

## 2. Applying Display Filters

### a. Display Only HTTP Packets

    tshark -r capture.pcap -Y "http"

*Explanation:*  
Filters and displays only HTTP protocol packets.

### b. Count HTTP Requests to `example.com`

    tshark -r capture.pcap -Y 'http.request and http.host == "example.com"' | wc -l

*Explanation:*  
Filters HTTP request packets with a Host header of `example.com` and pipes the output to `wc -l` to count the matching packets.

## 3. Extracting HTTP Headers

### Extract the Server Header from HTTP Responses

    tshark -r capture.pcap -Y 'http.response and ip.src==93.184.216.34' -T fields -e http.server

*Explanation:*  
Extracts the value of the HTTP **Server** header from responses coming from the IP address associated with `example.com`. Adjust the IP as needed.


## 4. Following TCP Streams

### a. Follow the First TCP Stream in ASCII

    tshark -r capture.pcap -q -z follow,tcp,ascii,0

*Explanation:*  
Reconstructs and displays the first TCP stream (stream index `0`) in ASCII format. The `-q` option suppresses the normal packet-by-packet output.

### b. Follow the First TCP Stream in Hex

    tshark -r capture.pcap -q -z follow,tcp,hex,0

*Explanation:*  
Displays the first TCP stream in hexadecimal format.



## 5. Finding the Correct TCP Stream

### a. List All TCP Stream Numbers

    tshark -r capture.pcap -T fields -e tcp.stream | sort -n | uniq

*Explanation:*  
Prints all unique TCP stream indexes present in the capture, helping you identify available streams.

### b. Identify the TCP Stream for a Specific Packet

For example, to determine which stream packet number 42 belongs to:

    tshark -r capture.pcap -T fields -e tcp.stream -Y "frame.number==42"

*Explanation:*  
Extracts the TCP stream number associated with packet 42. You can then follow that stream using the follow command.



## 6. Following a TCP Stream Based on Packet Number

Since **tshark** doesn’t allow following a TCP stream directly by specifying a packet number, you must:

1. **Find the TCP Stream Number** using the command from section 5b.
2. **Follow the Identified TCP Stream.**  
   For example, if packet 42 is in TCP stream 5:

       tshark -r capture.pcap -q -z follow,tcp,ascii,5



## 7. Extracting Files from HTTP Objects

**Command:**

    tshark -r capture.pcap --export-objects http,./output

*Explanation:*  
Scans for HTTP objects (such as files) within the capture and extracts them into the `./output` directory. Ensure that the output directory exists beforehand.



## 8. Finding Email Addresses in Captures

### a. Extract Email Addresses from SMTP Fields

    tshark -r capture.pcap -Y smtp -T fields -e smtp.req.mailfrom -e smtp.req.rcptto

*Explanation:*  
Filters SMTP packets and extracts the sender (`MAIL FROM`) and recipient (`RCPT TO`) email addresses.

### b. Search Raw Packet Data for Email Patterns

    tshark -r capture.pcap -V | grep -E -o "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}"

*Explanation:*  
Outputs verbose packet details and uses a regular expression with `grep` to find email address patterns. Adjust the regex if needed to reduce false positives.


## 9. Output Formatting with the **`-T`** Option

The **`-T`** option in tshark specifies the output format. Here are some common uses:

- **Default Text Format:**  
  Without **`-T`**, tshark outputs in a human-readable text format.

- **Fields Format:**  
  Use **`-T fields`** along with **`-e`** to output only specific fields.  
  Example:
      
      tshark -r capture.pcap -T fields -e ip.src -e ip.dst

- **Other Formats:**  
  - **`-T json`** or **`-T jsonraw`** for JSON output.
  - **`-T pdml`** for Packet Details Markup Language (XML format).
  - **`-T psml`** for a PostScript-based format.

*Explanation:*  
This option tailors the output for further processing or easier reading, depending on your needs.

---

## Additional Notes

- **Display vs. Capture Filters:**  
  Use **`-Y`** for display filters (post-capture) and **`-f`** for capture filters (during live capture). The syntaxes differ.
