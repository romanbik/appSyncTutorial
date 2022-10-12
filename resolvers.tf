# Create resolvers using the velocity templates

resource "aws_appsync_resolver" "createProject_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "createProject"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/create/createProject.request.vtl")
  response_template = file("./api/mapping-templates/default.response.vtl")
}

resource "aws_appsync_resolver" "delete_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Mutation"
  field       = "deleteProject"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/delete/deleteProject.request.vtl")
  response_template = file("./api/mapping-templates/project/delete/deleteProject.response.vtl")
}

resource "aws_appsync_resolver" "getProject_resolver" {
  api_id      = aws_appsync_graphql_api.appsync.id
  type        = "Query"
  field       = "project"
  data_source = aws_appsync_datasource.rds.name

  request_template  = file("./api/mapping-templates/project/getById/project.request.vtl")
  response_template = file("./api/mapping-templates/project/getById/project.response.vtl")
}
