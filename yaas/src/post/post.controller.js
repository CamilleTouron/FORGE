const prisma = require('@prisma/client');
const { PrismaClient } = prisma;
const prismaClient = new PrismaClient();

module.exports = {
  async create(req, res) {
    try {
      const post = await prismaClient.post.create({ data: req.body });
      return res.status(201).json(post);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  },
  async getAll(req, res) {
    try {
      const posts = await prismaClient.post.findMany();
      return res.status(200).json(posts);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  },
  async getOne(req, res) {
    try {
      const post = await prismaClient.post.findUnique({ where: { id: parseInt(req.params.id) } });
      return res.status(200).json(post);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  },
  async update(req, res) {
    try {
      const post = await prismaClient.post.update({ where: { id: parseInt(req.params.id) }, data: req.body });
      return res.status(200).json(post);
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  },
  async delete(req, res) {
    try {
      await prismaClient.post.delete({ where: { id: parseInt(req.params.id) } });
      return res.status(204).send();
    } catch (error) {
      return res.status(400).json({ error: error.message });
    }
  }
};
