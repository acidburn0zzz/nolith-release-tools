RSpec.shared_examples 'a sane Git repository' do
  it 'clones the repo in /tmp' do
    repo

    expect(File.exists?(repo_path)).to be_truthy
  end

  it 'replaces any existing dir with the same name in /tmp' do
    foo_path = File.join(repo_path, 'foo')
    FileUtils.mkpath(repo_path)
    FileUtils.touch(foo_path)
    expect(File.exists?(foo_path)).to be_truthy

    repo

    expect(File.exists?(foo_path)).to be_falsy
    expect(File.exists?(File.join(repo_path, 'README.md'))).to be_truthy
  end

  it 'performs a shallow cloning of the repo' do
    repo

    expect(Dir.chdir(repo_path) { `git log --oneline | wc -l`.to_i }).to eq(1)
  end
end
