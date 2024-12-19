<!-- @format -->

# **README: JSON Data Processing Script**

---

## **Overview**

This script processes JSON files by:

- Organizing data into **directories by unique keys** and **dates**.
- Managing **duplicates** and **missing data**.
- Logging all actions for transparency.
- Archiving processed JSON files.

---

## **Key Features**

📂 **Organized Output:**

- Creates directories for each unique news source.
- Subdivides key directories by **dates** (`YYYY-MM-DD`).

🔍 **Duplicate Handling:**

- Ensures no duplicate entries using **checksums**.
- Maintains a `checksum.txt` for each key.

🚫 **Error Management:**

- Skips entries with missing fields (`title`, `url`, or `checkSum`).
- Logs skipped entries and tracks missing data fields.

🗂️ **Archiving:**

- Moves processed JSON files to an archive folder organized by **processing date**.

📝 **Detailed Logs:**

- Logs include processed files, added articles, duplicates, and skipped entries.

---

## **How It Works**

### **Example Input JSON**

```json
{
  "thamilan": {
    "success": true,
    "data": [
      {
        "title": "Article 1",
        "url": "https://example.com/article1",
        "checkSum": "abc123",
        "href": "/article1",
        "timestamp": "2024-10-19T08:30:00Z",
        "isoTimestamp": "2024-10-19T08:30:00Z",
        "byline": "Author A",
        "baseUrl": "https://example.com"
      }
    ]
  },
  "adaderana": {
    "success": false,
    "data": []
  }
}
```

### **Output Directory Structure**

- After running the script, the output is neatly organized:

```yml
archive/
├── adaderana/
│   ├── 2024-10-19/
│   │   └── articles.json
│   ├── checksum.txt
│   └── urls.txt
├── thamilan/
│   ├── 2024-10-19/
│   │   └── articles.json
│   ├── checksum.txt
│   └── urls.txt
processed_data/
├── 2024-12-19/
│   └── archive-2024-10-19-17-41-all.json
process_log.txt
```

### \*\*Example Output Files

- 📄 articles.json (inside archive/key1/2024-12-19/):

```json
[
  {
    "title": "Article 1",
    "href": "/article1",
    "byline": "Author A",
    "timestamp": "2024-12-19T08:30:00Z",
    "url": "https://example.com/article1",
    "isoTimestamp": "2024-12-19T08:30:00Z",
    "baseUrl": "https://example.com",
    "checkSum": "abc123"
  }
]
```
