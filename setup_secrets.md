# Setting Up GitHub Secrets for Live API Tests

To enable live API testing in your CI/CD pipeline, you need to add your Discogs API token as a repository secret.

## Steps to Add the Secret

### 1. Get Your Discogs API Token
1. Go to [Discogs Settings](https://www.discogs.com/settings/developers)
2. Generate a Personal Access Token
3. Copy the token (you'll need it in the next step)

### 2. Add the Secret to GitHub
1. Go to your repository on GitHub
2. Click on **Settings** (in the repository, not your account)
3. In the left sidebar, click **Secrets and variables** → **Actions**
4. Click **New repository secret**
5. Set the following:
   - **Name**: `DISCOGS_API_TOKEN`
   - **Value**: Your personal access token from step 1
6. Click **Add secret**

### 3. Update the CI Workflow (Optional)
Once the secret is added, you can update the `.github/workflows/ci.yml` file to enable live API tests by replacing the placeholder steps with:

```yaml
- name: Run live API tests
  continue-on-error: true
  run: |
    echo "🚀 Running live API integration tests..."
    swift test --verbose --filter "LiveAPIIntegrationTests"
  env:
    DISCOGS_API_TOKEN: ${{ secrets.DISCOGS_API_TOKEN }}

- name: Run functional tests
  continue-on-error: true
  run: |
    echo "🚀 Running functional tests..."
    swift test --verbose \
      --filter "AuthenticationFunctionalTests" \
      --filter "DatabaseServiceFunctionalTests"
  env:
    DISCOGS_API_TOKEN: ${{ secrets.DISCOGS_API_TOKEN }}
```

## Testing Locally

To test the API integration locally, set the environment variable:

```bash
export DISCOGS_API_TOKEN="your_token_here"
swift test --filter "LiveAPIIntegrationTests"
```

## Security Notes

- ✅ The token is stored securely in GitHub Secrets
- ✅ It's only accessible to workflows in this repository
- ✅ Live tests only run on the `main` branch to prevent abuse
- ✅ Tests gracefully skip if the token is not available

## Troubleshooting

### "Context access might be invalid" Error
This error occurs when the secret doesn't exist yet. Follow the steps above to add the secret, then the error will disappear.

### Rate Limiting
The Discogs API has rate limits. The SDK includes automatic rate limiting to prevent hitting these limits during testing.
