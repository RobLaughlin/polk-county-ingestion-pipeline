import csv
import datetime
from tabulate import tabulate
from lazy_table.artists import Console

class Logger:
    headers = ['timestamp', 'status', 'source', 'destination', 'message']

    def __init__(self, output_csv_file) -> None:
        self.set_output_csv_file(output_csv_file)
        self.rows = []
        # Redraws the table in place, the same way lazy_table.stream() does.
        self.console = Console()
        self.console.init(None)
    
    def set_output_csv_file(self, output_csv_file, write_headers=True):
        self.file = open(output_csv_file, mode="w", newline="", encoding="utf-8")
        self.writer = csv.writer(self.file)
        if write_headers:
            self.writer.writerow(self.headers)

    def log(self, status, source="", destination="", message="", to_console=True):
        row = [
            datetime.datetime.now(datetime.timezone.utc),
            status,
            source,
            destination,
            message
        ]
        self.rows.append(row)
        if to_console:
            self.console.render(tabulate(self.rows, headers=self.headers))
        
        self.writer.writerow(row)
        self.file.flush()