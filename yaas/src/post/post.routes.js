const express = require('express');
const postController = require('./post.controller');
const router = express.Router();

router.post('/', postController.create);
router.get('/', postController.getAll);
router.get('/:id', postController.getOne);
router.put('/:id', postController.update);
router.delete('/:id', postController.delete);

module.exports = router;
