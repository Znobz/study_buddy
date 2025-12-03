import express from 'express';
import db from '../config/db.js';

const router = express.Router();

// Create new notification
const createNotification = async (req, res) => {
  try {
    const { assignmentId, userId, title, message, scheduledTime, status, notificationType } = req.body;
    
    const query = `
      INSERT INTO notifications (assignment_id, user_id, title, message, scheduled_time, status, notification_type)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `;
    
    const [result] = await db.query(query, [
      assignmentId,
      userId,
      title,
      message || `Don't forget about '${title}'! It's due soon.`,
      scheduledTime,
      status || 'pending',
      notificationType || 'assignment_reminder'
    ]);
    
    // Get the created notification
    const [rows] = await db.query(
      'SELECT * FROM notifications WHERE notification_id = ?',
      [result.insertId]
    );
    
    res.status(201).json(rows[0]);
  } catch (error) {
    console.error('Error creating notification:', error);
    res.status(500).json({ error: 'Failed to create notification' });
  }
};

// Get user's notifications
const getUserNotifications = async (req, res) => {
  try {
    const { userId } = req.params;
    const { status } = req.query; // Optional filter by status
    
    let query = `
      SELECT n.*, a.title as assignment_title, a.due_date
      FROM notifications n
      LEFT JOIN assignments a ON n.assignment_id = a.assignment_id
      WHERE n.user_id = ?
    `;
    
    const params = [userId];
    
    if (status) {
      query += ' AND n.status = ?';
      params.push(status);
    }
    
    query += ' ORDER BY n.scheduled_time ASC';
    
    const [rows] = await db.query(query, params);
    res.json(rows);
  } catch (error) {
    console.error('Error getting notifications:', error);
    res.status(500).json({ error: 'Failed to get notifications' });
  }
};

// Update notification status
const updateNotificationStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    const query = 'UPDATE notifications SET status = ?, updated_at = CURRENT_TIMESTAMP WHERE notification_id = ?';
    const [result] = await db.query(query, [status, id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    res.json({ success: true, message: 'Notification status updated' });
  } catch (error) {
    console.error('Error updating notification:', error);
    res.status(500).json({ error: 'Failed to update notification' });
  }
};

// Delete notification
const deleteNotification = async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = 'DELETE FROM notifications WHERE notification_id = ?';
    const [result] = await db.query(query, [id]);
    
    if (result.affectedRows === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    
    res.json({ success: true, message: 'Notification deleted' });
  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
};

// Routes
router.post('/notifications', createNotification);
router.get('/notifications/:userId', getUserNotifications);
router.put('/notifications/:id/status', updateNotificationStatus);
router.delete('/notifications/:id', deleteNotification);

export default router;