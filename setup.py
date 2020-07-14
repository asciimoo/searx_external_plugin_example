from setuptools import setup, find_packages

setup(
    name="plugin1",
    version="1.0",
    packages=find_packages(),
    package_data={'plugin1': ['resources/*']},
    zip_safe = False,
)
