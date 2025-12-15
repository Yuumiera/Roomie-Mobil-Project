// POST /api/conversations/:id/mark-read
// Mark conversation as read for a user
app.post('/api/conversations/:id/mark-read', async (req, res) => {
    try {
        const conversationId = req.params.id;
        const { userId } = req.body;

        if (!userId) {
            return res.status(400).json({ error: 'userId is required' });
        }

        const convoRef = db.collection('conversations').doc(conversationId);
        await convoRef.update({
            [`unreadCount.${userId}`]: 0
        });

        res.json({ message: 'Marked as read' });
    } catch (error) {
        console.error('Error marking as read:', error);
        res.status(500).json({ error: 'Failed to mark as read' });
    }
});

