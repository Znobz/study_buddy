import db from "../config/db.js";

export const create = async (req, res) => {
  try {
    if (!req.file) return res.status(400).json({ error: "No file uploaded" });

    const { mimetype, size, path } = req.file;

    const [result] = await db.execute(
      "INSERT INTO attachments (message_id, kind, url, mime, size) VALUES (NULL, ?, ?, ?, ?)",
      [mimetype.startsWith("image/") ? "image" : "file", path, mimetype, size]
    );

    res.status(201).json({
      attachmentId: result.insertId,
      kind: mimetype.startsWith("image/") ? "image" : "file",
      url: path,
      mime: mimetype,
      size,
    });
  } catch (err) {
    console.error("❌ upload error:", err);
    res.status(500).json({ error: "Upload failed" });
  }
};
