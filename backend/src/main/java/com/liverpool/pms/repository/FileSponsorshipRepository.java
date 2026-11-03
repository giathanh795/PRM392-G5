package com.liverpool.pms.repository;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.liverpool.pms.model.Sponsorship;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Repository;

import java.io.File;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.io.IOException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Repository
public class FileSponsorshipRepository implements SponsorshipRepository {

    private static final Logger logger = LoggerFactory.getLogger(FileSponsorshipRepository.class);
    @Value("${app.data.sponsorships-file:data/sponsorships.json}")
    private String storagePath;

    @Value("${app.data.contracts-directory:data/contracts}")
    private String contractsDirectoryPath;

    @Value("classpath:data/sponsorships.json")
    private Resource defaultSponsorshipsResource;

    private final ObjectMapper objectMapper;
    private final List<Sponsorship> sponsorships = new ArrayList<>();
    private File storageFile;
    private Path contractsDirectory;

    public FileSponsorshipRepository(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @PostConstruct
    public synchronized void initialize() {
        try {
            Path path = Paths.get(storagePath).toAbsolutePath();
            Files.createDirectories(path.getParent());
            storageFile = path.toFile();
            contractsDirectory = Paths.get(contractsDirectoryPath).toAbsolutePath();
            Files.createDirectories(contractsDirectory);

            if (storageFile.exists() && storageFile.length() > 0) {
                sponsorships.addAll(
                        objectMapper.readValue(storageFile, new TypeReference<>() {}));
                return;
            }

            try (InputStream input = defaultSponsorshipsResource.getInputStream()) {
                sponsorships.addAll(objectMapper.readValue(input, new TypeReference<>() {}));
            }
            persist();
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to initialize sponsorship storage", exception);
        }
    }

    @Override
    public synchronized List<Sponsorship> findAll() {
        return new ArrayList<>(sponsorships);
    }

    @Override
    public synchronized Optional<Sponsorship> findById(String id) {
        return sponsorships.stream()
                .filter(sponsorship -> id.equals(sponsorship.getId()))
                .findFirst();
    }

    @Override
    public synchronized Sponsorship save(Sponsorship sponsorship, byte[] contractBytes) {
        Sponsorship previous = findById(sponsorship.getId()).orElse(null);
        String oldStorageKey = previous == null ? null : previous.getContractStorageKey();
        String newStorageKey = oldStorageKey;
        boolean removeOldContract = sponsorship.isRemoveContract();

        try {
            if (contractBytes != null && contractBytes.length > 0) {
                String extension = extensionOf(sponsorship.getContractFileName());
                newStorageKey = UUID.randomUUID() + extension;
                Files.write(contractsDirectory.resolve(newStorageKey), contractBytes);
                sponsorship.setContractStorageKey(newStorageKey);
            } else if (removeOldContract) {
                newStorageKey = null;
                sponsorship.setContractStorageKey(null);
                sponsorship.setContractFileName("");
            } else if (previous != null) {
                sponsorship.setContractStorageKey(oldStorageKey);
                sponsorship.setContractFileName(previous.getContractFileName());
            } else {
                sponsorship.setContractStorageKey(null);
                sponsorship.setContractFileName("");
            }

            sponsorship.setRemoveContract(false);
            int index = indexOf(sponsorship.getId());
            if (index < 0) {
                sponsorships.add(0, sponsorship);
            } else {
                sponsorships.set(index, sponsorship);
            }
            persist();

            if (oldStorageKey != null && !oldStorageKey.equals(newStorageKey)) {
                try {
                    Files.deleteIfExists(contractsDirectory.resolve(oldStorageKey));
                } catch (IOException exception) {
                    logger.warn("Unable to remove replaced sponsorship contract", exception);
                }
            }
            return sponsorship;
        } catch (Exception exception) {
            if (contractBytes != null && newStorageKey != null && !newStorageKey.equals(oldStorageKey)) {
                try {
                    Files.deleteIfExists(contractsDirectory.resolve(newStorageKey));
                } catch (Exception cleanupException) {
                    exception.addSuppressed(cleanupException);
                }
            }
            if (previous == null) {
                sponsorships.removeIf(item -> sponsorship.getId().equals(item.getId()));
            } else {
                int index = indexOf(previous.getId());
                if (index >= 0) {
                    sponsorships.set(index, previous);
                }
            }
            throw new IllegalStateException("Unable to save sponsorship data", exception);
        }
    }

    @Override
    public synchronized boolean deleteById(String id) {
        Sponsorship existing = findById(id).orElse(null);
        if (existing == null) {
            return false;
        }
        sponsorships.remove(existing);
        try {
            persist();
            if (existing.getContractStorageKey() != null) {
                try {
                    Files.deleteIfExists(contractsDirectory.resolve(existing.getContractStorageKey()));
                } catch (IOException exception) {
                    logger.warn("Unable to remove deleted sponsorship contract", exception);
                }
            }
            return true;
        } catch (Exception exception) {
            sponsorships.add(0, existing);
            throw new IllegalStateException("Unable to delete sponsorship data", exception);
        }
    }

    @Override
    public synchronized Optional<Path> findContractPath(String id) {
        return findById(id)
                .map(Sponsorship::getContractStorageKey)
                .filter(key -> key != null && !key.isBlank())
                .map(contractsDirectory::resolve)
                .filter(Files::isRegularFile);
    }

    private int indexOf(String id) {
        for (int i = 0; i < sponsorships.size(); i++) {
            if (sponsorships.get(i).getId().equals(id)) {
                return i;
            }
        }
        return -1;
    }

    private String extensionOf(String fileName) {
        int dot = fileName.lastIndexOf('.');
        return dot < 0 ? "" : fileName.substring(dot).toLowerCase();
    }

    private void persist() {
        try {
            objectMapper.writerWithDefaultPrettyPrinter().writeValue(storageFile, sponsorships);
        } catch (Exception exception) {
            throw new IllegalStateException("Unable to persist sponsorship data", exception);
        }
    }
}
