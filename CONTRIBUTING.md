# Contributing to SerphunterRecon

Thank you for your interest in contributing! This document provides guidelines for various types of contributions.

## Code of Conduct

- Be respectful and professional
- Appreciate diverse perspectives
- Focus on what is best for the community
- Show empathy towards others

## How to Contribute

### Reporting Bugs

1. Check if the bug has already been reported
2. Use a clear, descriptive title
3. Provide specific examples to demonstrate the steps
4. Describe the observed and expected behavior
5. Include your environment details (OS, Bash version, tool versions)

### Suggesting Enhancements

1. Use a clear, descriptive title
2. Provide a detailed description
3. Explain why this enhancement would be useful
4. List similar features in other tools

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Style Guidelines

### Bash Code

- Use 4 spaces for indentation
- Add comments for complex logic
- Use meaningful variable names
- Follow the existing code structure
- Test your changes thoroughly

### Commit Messages

- Use imperative mood ("Add feature" not "Added feature")
- Reference issues and pull requests liberally
- Keep the first line concise (50 characters or less)
- Add detailed explanation in the body if needed

### Documentation

- Keep README.md updated with changes
- Add comments to new functions
- Update CHANGELOG.md for releases
- Include usage examples

## Testing

Before submitting a PR:

1. Test with multiple domains
2. Test both sequential and parallel modes
3. Test with and without HTTP probing
4. Verify all enumeration sources work
5. Check for edge cases and error handling

## Development Setup

```bash
# Clone the repository
git clone https://github.com/yourusername/serphunter-recon.git
cd serphunter-recon

# Create a feature branch
git checkout -b feature/your-feature

# Make your changes
# ... edit files ...

# Test thoroughly
./serphunter.sh -d example.com
./serphunter.sh -d example.com --parallel
./serphunter.sh -d example.com --http-probe

# Commit your changes
git add .
git commit -m "Add your feature description"

# Push to your fork
git push origin feature/your-feature

# Create a Pull Request on GitHub
```

## Areas for Contribution

### High Priority
- Bug fixes and stability improvements
- Performance optimization
- Documentation improvements
- Additional enumeration sources
- API integrations

### Medium Priority
- Feature enhancements
- Code refactoring
- Test coverage
- Security improvements

### Community
- Wiki documentation
- Tutorial creation
- Blog posts
- Video demonstrations

## Review Process

All contributions will be reviewed for:

- Code quality and consistency
- Functionality and testing
- Documentation
- Security implications
- Performance impact

## Recognition

Contributors will be recognized in:
- README.md contributors section
- CHANGELOG.md release notes
- GitHub contributors graph

## Questions?

- Check the README.md for usage questions
- Review existing issues for common problems
- Create a new issue for discussion

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for making SerphunterRecon better! 🎯
