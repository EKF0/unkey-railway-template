# Unkey Railway Template

This template deploys [Unkey](https://unkey.dev) (an open-source API key management platform) on Railway with MySQL and Redis.

## Services

- **Unkey**: The main API key management service
- **MySQL**: Database for storing Unkey data
- **Redis**: Cache for Unkey

## Environment Variables

The template automatically sets the following environment variables:

- `UNKEY_DATABASE_PRIMARY`: Set to the MySQL connection string
- `UNKEY_REDIS_URL`: Set to the Redis connection string
- `UNKEY_ROOT_KEY`: A generated 32-character hex string used as the root key for Unkey

After deployment, you will need to:

1. Note the generated `UNKEY_ROOT_KEY` from the Unkey service's variables
2. Redeploy the Unkey service (if not done automatically)
3. Access the Unkey dashboard via the public URL provided by Railway for the Unkey service

## Development

To run locally, you would need to set up MySQL and Redis, then run the Unkey binary with the appropriate environment variables.

## License

This template is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

The Unkey application itself is licensed under the MIT License as well (see [Unkey's License](https://github.com/unkeyed/unkey/blob/main/LICENSE)).