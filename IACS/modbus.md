The script connects to a Modbus TCP server using an IP address provided as a command-line argument, then continuously reads 16 holding registers starting at address 1 and prints their values every second.

```Python
#!/usr/bin/env python3

import sys
import time
from pymodbus.client.sync import ModbusTcpClient as ModbusClient
from pymodbus.exceptions import ConnectionException

ip = sys.argv[1]
client = ModbusClient(ip, port=502)
client.connect()
while True:
    rr = client.read_holding_registers(1, 16)
    print(rr.registers)
    time.sleep(1)
```
The script connects to a Modbus TCP server using an IP address from the command line, then writes a specified integer value to a given register (also provided as an argument).


```Python
#!/usr/bin/env python3

import sys
import time
from pymodbus.client.sync import ModbusTcpClient as ModbusClient
from pymodbus.exceptions import ConnectionException

ip = sys.argv[1]
registry = int(sys.argv[2])
value = int(sys.argv[3])
client = ModbusClient(ip, port=502)
client.connect()
client.write_register(registry, value)
```






