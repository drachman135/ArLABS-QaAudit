-- Enable UUID extension if not enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Projects Table
CREATE TABLE IF NOT EXISTS projects (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  color TEXT DEFAULT '#6366F1', -- Indigo primary default
  icon TEXT DEFAULT 'folder_outlined',
  status TEXT NOT NULL DEFAULT 'Active', -- Active / Archived
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ -- Nullable for soft deletes
);

-- 2. Modules Table
CREATE TABLE IF NOT EXISTS modules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Features Table
CREATE TABLE IF NOT EXISTS features (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_id UUID NOT NULL REFERENCES modules(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 4. Functions Table
CREATE TABLE IF NOT EXISTS functions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  feature_id UUID NOT NULL REFERENCES features(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 5. Audits Table
CREATE TABLE IF NOT EXISTS audits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  function_id UUID UNIQUE NOT NULL REFERENCES functions(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'Not Tested',
  priority TEXT, -- P0, P1, P2, P3
  notes TEXT,
  auditor_name TEXT,
  last_audited_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indices for performance and sorting
CREATE INDEX IF NOT EXISTS idx_projects_deleted_at ON projects(deleted_at);
CREATE INDEX IF NOT EXISTS idx_modules_project_id_order ON modules(project_id, order_index);
CREATE INDEX IF NOT EXISTS idx_features_module_id_order ON features(module_id, order_index);
CREATE INDEX IF NOT EXISTS idx_functions_feature_id_order ON functions(feature_id, order_index);
CREATE INDEX IF NOT EXISTS idx_audits_function_id ON audits(function_id);

-- Trigger to automatically update updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_projects_updated_at
  BEFORE UPDATE ON projects
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_modules_updated_at
  BEFORE UPDATE ON modules
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_features_updated_at
  BEFORE UPDATE ON features
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_functions_updated_at
  BEFORE UPDATE ON functions
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

CREATE TRIGGER update_audits_updated_at
  BEFORE UPDATE ON audits
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();

-- 6. Bugs Table
CREATE TABLE IF NOT EXISTS bugs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  audit_id UUID NOT NULL REFERENCES audits(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'Medium', -- Critical, High, Medium, Low
  status TEXT NOT NULL DEFAULT 'Open', -- Open, In Progress, Ready To Test, Resolved, Closed, Rejected
  steps_to_reproduce TEXT,
  expected_result TEXT,
  actual_result TEXT,
  assigned_to TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  deleted_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_bugs_audit_id ON bugs(audit_id);
CREATE INDEX IF NOT EXISTS idx_bugs_deleted_at ON bugs(deleted_at);

CREATE TRIGGER update_bugs_updated_at
  BEFORE UPDATE ON bugs
  FOR EACH ROW
  EXECUTE PROCEDURE update_updated_at_column();
