import libgit2

/// Represents the status of a file in the repository.
public struct StatusEntry: LibGit2RawRepresentable {
    /// The status of the file.
    ///
    /// This is an array of ``Status-swift.enum`` cases because a file can have multiple statuses.
    /// For example, if a file is modified than staged, it will be ``Status-swift.enum/indexModified`` but if it is
    /// modified again before the commit, it will be ``Status-swift.enum/workingTreeModified`` as well. As is the case
    /// with `git status` command.
    public let status: [Status]

    /// The differences between the file in HEAD and the file in the index.
    ///
    /// This represents the changes that have been staged but not committed.
    /// If the file is not staged, this is `nil`.
    public let index: Diff.Delta?

    /// The differences between the file in the index and the file in the working directory.
    ///
    /// This represents the changes on working tree that are not staged.
    /// If the file is staged and there is no additional changes, this is `nil`.
    public let workingTree: Diff.Delta?

    init(raw: git_status_entry) {
        status = Status.from(raw.status.rawValue)

        index = if let rawDelta = raw.head_to_index?.pointee {
            Diff.Delta(raw: rawDelta)
        } else { nil }

        workingTree = if let rawDelta = raw.index_to_workdir?.pointee {
            Diff.Delta(raw: rawDelta)
        } else { nil }
    }

    /// Represents the status of a file in the repository.
    ///
    /// This enumeration provides a detailed status of files in a Git repository. Each case corresponds to a specific
    /// status that a file can have in the repository, similar to the output of the `git status` command.
    public enum Status {
        /// The file is tracked and its content has no changes.
        case current

        /// The file is `untracked` and it is staged.
        ///
        /// This is a file that is in the index which is not tracked earlier by Git.
        case indexNew

        /// The file is modified and staged.
        ///
        /// This is a `tracked` file that has changes and it's in the index.
        case indexModified

        /// The file is deleted and staged.
        ///
        /// This is a `tracked` file that is deleted and it's in the index.
        case indexDeleted

        /// The file is renamed and staged.
        ///
        /// This is a `tracked` file that is renamed and staged.
        case indexRenamed

        /// The file's type is changed and staged.
        ///
        /// This is a `tracked` file that has its type changed and staged.
        case indexTypeChange

        /// The file is `untracked` and in the working tree (not staged).
        ///
        /// This is a file that is not staged yet and not tracked by Git. Newly created files are in this state.
        case workingTreeNew

        /// The file is modified which in the working tree.
        ///
        /// This is a `tracked` file that has changes and it's in the working tree.
        case workingTreeModified

        /// The file is deleted in the working tree.
        ///
        /// This is a `tracked` file that is deleted and it's in the working tree.
        case workingTreeDeleted

        /// The file is renamed in the working tree.
        ///
        /// This is a `tracked` file that is renamed and it's in the working tree.
        case workingTreeRenamed

        /// The file's type is changed in the working tree.
        ///
        /// This is a `tracked` file that has its type changed and it's in the working tree.
        case workingTreeTypeChange

        case workingTreeUnreadable

        case ignored

        case conflicted

        static func from(_ flags: UInt32) -> [Status] {
            Status.statusMapping.filter { flags & $0.value.rawValue != 0 }.map(\.key)
        }
    }
}

private extension StatusEntry.Status {
    // We use this instead of direct dictionary because this makes sure the result is ordered.
    static let statusMapping: [(key: StatusEntry.Status, value: git_status_t)] = [
        (.current, GIT_STATUS_CURRENT),

        (.indexNew, GIT_STATUS_INDEX_NEW),
        (.indexModified, GIT_STATUS_INDEX_MODIFIED),
        (.indexDeleted, GIT_STATUS_INDEX_DELETED),
        (.indexRenamed, GIT_STATUS_INDEX_RENAMED),
        (.indexTypeChange, GIT_STATUS_INDEX_TYPECHANGE),

        (.workingTreeNew, GIT_STATUS_WT_NEW),
        (.workingTreeModified, GIT_STATUS_WT_MODIFIED),
        (.workingTreeDeleted, GIT_STATUS_WT_DELETED),
        (.workingTreeTypeChange, GIT_STATUS_WT_TYPECHANGE),
        (.workingTreeRenamed, GIT_STATUS_WT_RENAMED),
        (.workingTreeUnreadable, GIT_STATUS_WT_UNREADABLE),

        (.ignored, GIT_STATUS_IGNORED),
        (.conflicted, GIT_STATUS_CONFLICTED)
    ]
}
