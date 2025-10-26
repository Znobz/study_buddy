const db = require('../config/db');

exports.create = async (req, res) => {
  try {
    // Multer puts the file at req.file
    if (!req.file) return res.status(400).json({ error: 'No file uploaded' });

    // TODO: Validate type/size; move to S3/Cloudinary and get a public URL
    const { mimetype, size, filename, path } = req.file;

    // For now we store the local path as url; replace with your S3/Cloudinary URL
    const [result] = await db.execute(
      'INSERT INTO attachments (message_id, kind, url, mime, size) VALUES (NULL, ?, ?, ?, ?)',
      [mimetype.startsWith('image/') ? 'image' : 'file', path, mimetype, size]
    );

    res.status(201).json({
      attachmentId: result.insertId,
      kind: mimetype.startsWith('image/') ? 'image' : 'file',
      url: path,
      mime: mimetype,
      size
    });
  } catch (err) {
    console.error('upload error', err);
    res.status(500).json({ error: 'Upload failed' });
  }
};