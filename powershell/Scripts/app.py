from flask import Flask, render_template, send_file, abort
import os
import json
import csv
import glob
from datetime import datetime
from deepdiff import DeepDiff

app = Flask(__name__)

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
OUTPUT_DIR = os.path.join(BASE_DIR, "Output")

@app.route("/")
def index():
    servers = sorted(os.listdir(OUTPUT_DIR))
    return render_template("index.html", servers=servers)

@app.route("/server/<server>")
def server_view(server):
    server_dir = os.path.join(OUTPUT_DIR, server)
    if not os.path.isdir(server_dir):
        abort(404)
    scripts = sorted(os.listdir(server_dir))
    return render_template("server.html", server=server, scripts=scripts)

@app.route("/script/<server>/<script>")
def script_view(server, script):
    script_dir = os.path.join(OUTPUT_DIR, server, script)
    if not os.path.isdir(script_dir):
        abort(404)

    # Get all matching files
    files = glob.glob(os.path.join(script_dir, f"{script}-*.json")) + \
            glob.glob(os.path.join(script_dir, f"{script}-*.csv"))

    # Sort them based on timestamp in filename
    def extract_timestamp(file_path):
        filename = os.path.basename(file_path)
        match = re.search(r'-(\d{8}-\d{6})\.', filename)
        if match:
            try:
                return datetime.strptime(match.group(1), "%Y%m%d-%H%M%S")
            except ValueError:
                pass
        return datetime.min

    files = sorted(files, key=extract_timestamp)

    if len(files) == 0:
        abort(404)

    latest_file = files[-1]
    previous_file = files[-2] if len(files) >= 2 else None
    ext = os.path.splitext(latest_file)[1].lower()

    latest_content = open(latest_file, encoding="utf-8-sig").read()
    previous_content = open(previous_file, encoding="utf-8-sig").read() if previous_file else None
    diff_output = None
    parsed_output = None

    if ext == ".json":
        try:
            latest_json = json.loads(latest_content)
            parsed_output = latest_json
            if previous_content:
                previous_json = json.loads(previous_content)
                diff = DeepDiff(previous_json, latest_json, ignore_order=True)
                diff_output = json.dumps(diff, indent=2)
        except Exception as e:
            diff_output = f"[Error parsing JSON diff] {e}"

    elif ext == ".csv":
        try:
            latest_lines = latest_content.strip().splitlines()
            previous_lines = previous_content.strip().splitlines() if previous_content else []

            reader = csv.reader(latest_lines)
            parsed_output = list(reader)

            from difflib import unified_diff
            diff = unified_diff(previous_lines, latest_lines, fromfile='previous', tofile='latest', lineterm='')
            diff_output = '\n'.join(diff)
        except Exception as e:
            diff_output = f"[Error parsing CSV diff] {e}"

    return render_template("script.html",
                           server=server,
                           script=script,
                           extension=ext,
                           parsed_output=parsed_output,
                           raw_output=latest_content,
                           diff=diff_output)
if __name__ == "__main__":
    app.run(debug=True)
