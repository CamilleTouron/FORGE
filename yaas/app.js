const express = require('express')
const app = express()
const user_routes = require('./src/user/user.routes')
const post_routes = require('./src/post/post.routes')

const port = process.env.PORT || 3000
const project_name = process.env.PROJECT_NAME || 'new_project'

app.use(express.json())

app.use('/user', user_routes)
app.use('/post', post_routes)

app.listen(port, () => console.log(`Server running on port 3000`))
