package libfuse

import (
	"errors"

	"bazil.org/fuse"
	"bazil.org/fuse/fs"
	"github.com/keybase/kbfs/libkbfs"
	"golang.org/x/net/context"
)

// DisableUpdatesFileName is the name of the KBFS update-disabling
// file -- it can be reached anywhere within a top-level folder.
const DisableUpdatesFileName = ".kbfs_disable_updates"

// EnableUpdatesFileName is the name of the KBFS update-enabling
// file -- it can be reached anywhere within a top-level folder.
const EnableUpdatesFileName = ".kbfs_enable_updates"

// UpdatesFile represents a write-only file where any write of at
// least one byte triggers either disabling remote folder updates and
// conflict resolution, or re-enabling both.  It is mainly useful for
// testing.
type UpdatesFile struct {
	folder *Folder
	enable bool
}

var _ fs.Node = (*UpdatesFile)(nil)

// Attr implements the fs.Node interface for UpdatesFile.
func (f *UpdatesFile) Attr(ctx context.Context, a *fuse.Attr) error {
	a.Size = 0
	a.Mode = 0222
	return nil
}

var _ fs.Handle = (*UpdatesFile)(nil)

var _ fs.HandleWriter = (*UpdatesFile)(nil)

// Write implements the fs.HandleWriter interface for UpdatesFile.
func (f *UpdatesFile) Write(ctx context.Context, req *fuse.WriteRequest,
	resp *fuse.WriteResponse) (err error) {
	ctx = NewContextWithOpID(ctx, f.folder.fs.log)
	f.folder.fs.log.CDebugf(ctx, "UpdatesFile (enable: %t) Write", f.enable)
	defer func() { f.folder.fs.reportErr(ctx, err) }()
	if len(req.Data) == 0 {
		return nil
	}

	f.folder.updateMu.Lock()
	defer f.folder.updateMu.Unlock()
	if f.enable {
		if f.folder.updateChan == nil {
			return errors.New("Updates are already enabled")
		}
		err = libkbfs.RestartCRForTesting(f.folder.fs.config,
			f.folder.folderBranch)
		if err != nil {
			return err
		}
		f.folder.updateChan <- struct{}{}
		close(f.folder.updateChan)
		f.folder.updateChan = nil
	} else {
		if f.folder.updateChan != nil {
			return errors.New("Updates are already disabled")
		}
		f.folder.updateChan, err =
			libkbfs.DisableUpdatesForTesting(f.folder.fs.config,
				f.folder.folderBranch)
		if err != nil {
			return err
		}
		err = libkbfs.DisableCRForTesting(f.folder.fs.config,
			f.folder.folderBranch)
		if err != nil {
			return err
		}
	}

	resp.Size = len(req.Data)
	return nil
}
