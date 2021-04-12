ExUnit.start()

# Ensure that symlink to custom ecto priv directory exists.
source = CoderRing.Test.Repo.config()[:priv]
target = Application.app_dir(:coder_ring, source)

File.rm_rf(target)
File.mkdir_p(target)
File.rmdir(target)
:ok = :file.make_symlink(Path.expand(source), target)

# Run migrations.
Mix.Task.run("ecto.drop", ~w(--quiet))
Mix.Task.run("ecto.create", ~w(--quiet))
Mix.Task.run("ecto.migrate", ~w(--quiet))

{:ok, _pid} = CoderRing.Test.Repo.start_link()

# Seed ring data.
CoderRing.populate_rings_if_empty()
