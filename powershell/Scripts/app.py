from flask import Flask, render_template, send_file, abort
import os
import json
import csv
from pathlib import Path

app = Flask(__name__)

# Path to your collected output data
DATA_FOLDER = Path("./Output")

@app.route("/")
def index():
    if not DATA_FOLDER.exists():
        return "Data folder not found.", 500

    servers = sorted(
        [d.name for d in DATA_FOLDER.iterdir() if d.is_dir()],
        key=lambda name: os.path.getmtime(DATA_FOLDER / name),
        reverse=True
    )
    return render_template("index.html", servers=servers)

@app.route("/server/<server_name>")
def server_view(server_name):
    server_path = DATA_FOLDER / server_name
    if not server_path.exists():
        abort(404)

    scripts = sorted(
        [d.name for d in server_path.iterdir() if d.is_dir()],
        key=lambda name: os.path.getmtime(server_path / name),
        reverse=True
    )
    return render_template("server_view.html", server=server_name, scripts=scripts)

@app.route("/server/<server_name>/<script_name>")
def script_view(server_name, script_name):
    script_path = DATA_FOLDER / server_name / script_name
    if not script_path.exists():
        abort(404)

    files = sorted(
        [f for f in script_path.glob("*") if f.is_file()],
        key=os.path.getmtime,
        reverse=True
    )

    if not files:
        return render_template("no_output.html", server=server_name, script=script_name)

    latest_file = files[0]

    # Determine file type
    if latest_file.suffix == ".json":
        with open(latest_file, "r", encoding="utf-8-sig") as f:
            data = json.load(f)
        return render_template("view_json.html", server=server_name, script=script_name, data=data)

    elif latest_file.suffix == ".csv":
        with open(latest_file, "r", encoding="utf-8") as f:
            reader = csv.reader(f)
            rows = list(reader)
        return render_template("view_csv.html", server=server_name, script=script_name, rows=rows)

    else:
        return send_file(latest_file)

if __name__ == "__main__":
    app.run(debug=True)
