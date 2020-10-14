# GraphQL migration strategy and guidelines:


1. Integrate Absinthe, GraphQL implementation for Elixir that will handle running GraphQL queries submitted via Phoenix. https://www.howtographql.com/graphql-elixir/0-introduction/

2. Avoid the database queries in Authorization as its costly and it runs for every request. (Put School id in authorization token, that will help in avoiding querying)

3. Stop passing context to Core. Just pass school_id, Context makes code messy and the only data we need from it is either user id or school id.

4. Make new modules for GraphQL resolvers and core modules, Reuse methods from existing implementation but it would be best if we replicate them in the new modules especially when change is required for GraphQL. That way we make sure that existing apps won't break.

5. Though out the application we have seen that there is no use of database transaction, that will cause problems when we have a bigger user roles and more scenarios and failures will occur. Take care of database transactions for new implementation and when encounter an implementation where transaction should be used but isn't, Fix that.

6. Avoid querying all database records and thoughtfully implement listing APIs especially in cases when querying related data for lists. Instead of using preload functions, get related data for all records with joins or a separate query, whichever is suitable.

7. Be careful with GraphQL query designing, Design in a way so that the client cannot exploit the backend i-e Be explicit instead of being generic, Avoid querying child objects, instead write a separate query for child objects.

8. Keep the code organization such that its easy to maintain, write separate absinthe types, separate resolver, separate main module and separate queries module for each app module.
